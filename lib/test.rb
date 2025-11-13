cases = [[500,100],[0,1000],[10,10],[50,200]]

def monotonic_fit(data)
  xs, ys = data.transpose

  # Sort y values descending, assign them to xs (already sorted)
  sorted_ys = ys.sort.reverse
  averaged_ys = ys.zip(sorted_ys).map { |y1,y2| 0.5*(y1+y2)  }
  sorted_ys = averaged_ys.sort.reverse
  realigned_data = xs.zip(sorted_ys)

  return realigned_data
end

def soft_logit(y, epsilon = 1e-12)
  y = [[y, epsilon].max, 1 - epsilon].min
  # return Math.log((1 - y) / y)
  -Math.tan((y+ 0.5)*Math::PI)
end

def fit_weighted_sigmoid(xy_data)
  xy_data = monotonic_fit(xy_data)
  s_w  = 0# ws.sum
  s_x  = 0# ws.zip(x_data).map { |w, x| w * x }.sum
  s_z  = 0#  ws.zip(zs).map     { |w, z| w * z }.sum
  s_xx = 0#  ws.zip(x_data).map { |w, x| w * x * x }.sum
  s_xz = 0#  ws.zip(x_data.zip(zs)).map { |w, (x, z)| w * x * z }.sum

  xy_data.each do |x,y|
    z = soft_logit(y) #   Math.log((1 - y) / y) = ln(1-y) - ln (y)
    w = 1.0 / (1.0 + z**2)  # 1 / (1 +   Math.log**2((1 - y) / y))
    wxz = 1.0 / (1.0/z + z)
    s_w += w
    s_x += w * x
    s_z += wxz # w * z
    s_xx += w * x * x
    s_xz += wxz * x  # w * z * x
  end

  denom = s_w * s_xx - s_x * s_x + 1
  a = (s_w * s_xz - s_x * s_z + 1) / denom
  c = (s_z - a * s_x) / s_w
  b = -c / a
  # return a, b
  # ax + c = 0
  mean = -c / a
  slope = -a/Math::PI
  return [mean, slope]
end

def estimate_sigmoid(y_by_x)
  y_by_x = monotonic_fit(y_by_x)
  s_w  = 0# ws.sum
  s_x  = 0# ws.zip(x_data).map { |w, x| w * x }.sum
  s_z  = 0#  ws.zip(zs).map     { |w, z| w * z }.sum
  s_xx = 0#  ws.zip(x_data).map { |w, x| w * x * x }.sum
  s_xz = 0#  ws.zip(x_data.zip(zs)).map { |w, (x, z)| w * x * z }.sum
  y_by_x.each_cons(2) do |(x1,y1),(x2,y2)|
    ss = (y2 - y1)/(x2-x1).abs
    (x1..x2 - 1).each do |xx|
      x = xx
      y = y1 + (x-x1)*ss
      y = (y2-y1).abs > 1e-16 ? [y1,y2].min + (y - [y1,y2].min)**2/(y2-y1).abs : y
      z = soft_logit(y) #   Math.log((1 - y) / y) = ln(1-y) - ln (y)
      wmult = (y2 - y1 + 1) / (x2 - x1 + 1).abs
      w =   wmult/ (1.0 + z**2)
      wxz = wmult / (z + 1.0 / z)
      s_w += w
      s_x += w * x
      s_z += wxz # w * z
      s_xx += w * x * x
      s_xz += wxz * x  # w * z * x
      # puts [x,y,w, w * x,wxz,w * x * x,wxz * x ].to_s
    end
  end
  denom = s_w * s_xx - s_x * s_x + 1e-15
  a = (s_w * s_xz - s_x * s_z + 1e-15) / denom
  c = (s_z - a * s_x) / s_w
  mean = -c / a
  slope = -a/Math::PI
  return [mean, slope,s_w,s_x,s_z,s_xx,s_xz]
end

# Box-Muller transform to generate normal distribution values
def generate_normal(mean, std_dev)
  u1 = rand
  u2 = rand
  z0 = Math.sqrt(-2.0 * Math.log(u1)) * Math.cos(2.0 * Math::PI * u2)
  z0 * std_dev + mean
end

def normal_pdf(x, mean, std_dev)
  coefficient = 1.0 / (std_dev * Math.sqrt(2 * Math::PI))
  exponent = -((x - mean)**2) / (2 * std_dev**2)
  coefficient * Math.exp(exponent)
end

# Approximate error function (erf) using Abramowitz and Stegun formula
def erf(x)
  # constants
  a1 =  0.254829592
  a2 = -0.284496736
  a3 =  1.421413741
  a4 = -1.453152027
  a5 =  1.061405429
  p  =  0.3275911

  sign = x < 0 ? -1 : 1
  x = x.abs

  t = 1.0 / (1.0 + p * x)
  y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * Math.exp(-x * x)

  sign * y
end

# CDF for normal distribution
def normal_cdf(x, mean, std_dev)
  z = (x - mean) / (std_dev * Math.sqrt(2.0))
  0.5 * (1.0 + erf(z))
end

cases.each do |mean, std_dev|
  mean *= 1.0
  std_dev *= 1.0
  values = [[0,1]]
  # Generate and print normal values for x from 1 to 100_000
  sum = 0
  (1..1000).each do |x|
    normal_value = normal_cdf(x, mean, std_dev)
    values.append([x,1 - normal_value])
  end
  values.append([1001,0])
  pick_service = PickWordInSetService.new({option_dialect: Dialect.find_by_name('english'),\
    target_dialect: Dialect.find_by_name('japanese'), \
    display_dialects: [Dialect.find_by_name('english')]})
  sigmoid = pick_service.guesstimate_sigmoid(values)
  better_sigmoid = fit_weighted_sigmoid(values)
  ebs = estimate_sigmoid(values)
  slope = -Math.sqrt(2)/(Math.sqrt(Math::PI)*std_dev)
  puts "#{[mean,slope].to_s} <=> #{sigmoid.to_s} <=> #{better_sigmoid.to_s}  <> #{ebs.to_s}"
end

values1 = [[0, 1.0], [1, 0.9999999999999996], [2, 0.9999999999999993], [3, 0.9999999999999993], [4, 0.9523809523809522], [5, 0.909090909090909], [6, 0.9999999999999993], [7, 0.9999999999999993], [8, 0.9999999999999998], [9, 1.0], [10, 0.9999999999999991], [11, 0.9999999999999991], [12, 0.9999999999999991], [13, 0.9999999999999991], [14, 0.9999999999999991], [15, 0.9999999999999991], [16, 0.9999999999999991], [17, 0.9999999999999998], [19, 0.9999999999999991], [26, 1.0], [30, 1.0], [33, 0.9999999999999991], [37, 1.0], [38, 0.9999999999999991], [44, 0.9999999999999991], [45, 1.0], [52, 0.9999999999999991], [58, 0.9999999999999999], [59, 0.9999999999999991], [63, 1.0], [64, 0.9999999999999991], [72, 0.9999999999999996], [77, 0.9999999999999993], [80, 0.9999999999999991], [82, 0.9999999999999991], [85, 0.9999999999999991], [87, 0.5], [89, 1.0], [94, 0.9999999999999998], [95, 0.9999999999999991], [96, 0.9999999999999999], [97, 0.9999999999999998], [106, 0.9999999999999991], [107, 0.9999999999999993], [109, 0.9999999999999991], [112, 0.9999999999999998], [114, 1.0], [117, 0.8571428571428571], [118, 1.0], [121, 0.9999999999999991], [128, 0.9999999999999991], [135, 0.9999999999999991], [136, 0.9999999999999999], [140, 0.9999999999999999], [144, 1.0], [146, 1.0], [147, 0.9999999999999998], [155, 1.0], [7259, 0.5], [7273, 0.5], [7274, 0.5], [7277, 0.5], [7278, 0.5], [7279, 0.5], [7283, 0.5], [7319, 0.5], [7320, 0.5], [7329, 0.5], [7522, 0.5], [7527, 0.5], [7537, 0.5], [7568, 0.5], [7571, 0.5], [7578, 0.5], [7600, 0.5], [7603, 0.5], [7608, 0.5], [7611, 0.5], [7612, 0.5], [7614, 0.5], [7618, 0.5], [7621, 0.5], [7624, 0.5], [7629, 0.5], [7631, 0.5], [7636, 0.5], [7637, 0.5], [7645, 0.5], [7648, 0.5], [7649, 0.5], [7650, 0.5], [7655, 0.5], [7657, 0.5], [7663, 0.5], [7665, 0.5], [7668, 0.5], [7670, 0.5], [7680, 0.5], [7684, 0.5], [7686, 0.5], [7694, 0.5], [7695, 0.5], [7696, 0.5], [7702, 0.5], [7706, 0.5], [7707, 0.5], [7712, 0.5], [7714, 0.5], [7731, 0.5], [7733, 0.5], [7734, 0.5], [7739, 0.5], [19407, 9.999999999999981e-16], [19468, 9.999999999999981e-16], [19472, 9.999999999999981e-16], [19473, 9.999999999999981e-16], [77733, 0]]

values2 = [[1,1],[2,1],[3,1],[4,0.5],[5,1],[6,0.5],[7,0],[8,0],[69,0],[70,1],[71,0],[50000,0]]
values3 = [[0, 1.0], [1, 0.9999999999999996], [2, 0.9999999999999993], [3, 0.9999999999999993], [4, 0.9999999999999999], [5, 0.7777777777777777], [6, 0.9999999999999993], [7, 0.9999999999999993], [8, 0.9999999999999999], [9, 0.9999999999999996], [10, 0.9999999999999991], [11, 0.9999999999999991], [12, 0.9999999999999991], [13, 0.9999999999999991], [14, 0.9999999999999991], [15, 0.9999999999999991], [16, 0.9999999999999991], [17, 0.9999999999999991], [26, 0.9999999999999996], [30, 0.9999999999999993], [37, 0.9999999999999993], [45, 0.9999999999999996], [58, 0.9999999999999991], [59, 0.9999999999999991], [63, 0.9999999999999996], [64, 0.9999999999999991], [72, 0.9999999999999996], [77, 0.9999999999999993], [87, 0.5], [89, 0.9999999999999993], [94, 0.9999999999999991], [96, 0.9999999999999993], [107, 0.9999999999999993], [112, 0.9999999999999991], [114, 0.9999999999999991], [117, 0.9999999999999991], [118, 0.9999999999999991], [121, 0.9999999999999991], [136, 0.9999999999999991], [19407, 9.999999999999981e-16], [19468, 9.999999999999981e-16], [19472, 9.999999999999981e-16], [77733, 2.499999999999999e-16], [77734, 2.499999999999999e-16], [77733, 0]]


[values1,values2,values3].each do |values|
  values = monotonic_fit(values)
  puts values.to_s
  epsilon = 1e-20
  values.each do |x|
    x[1] = [[x[1], epsilon].max, 1- epsilon].min
  end
  # puts values.to_s
  pick_service = PickWordInSetService.new({option_dialect: Dialect.find_by_name('english'),\
    target_dialect: Dialect.find_by_name('japanese'), \
    display_dialects: [Dialect.find_by_name('english')]})
  sigmoid_g =  pick_service.guesstimate_sigmoid(values)
  sigmoid_e =  pick_service.estimate_sigmoid(values)
  better_sigmoid = fit_weighted_sigmoid(values)
  ebs = estimate_sigmoid(values)
  puts "guestimate: #{sigmoid_g.to_s} <=>  estimate: #{sigmoid_e.to_s} <=> weighted: #{better_sigmoid.to_s}  <> with lines #{ebs.to_s}"
end
