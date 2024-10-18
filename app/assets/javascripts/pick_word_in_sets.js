(function() {
  root = typeof exports !== "undefined" && exports !== null ? exports : this;
  root.fit_all_text = function (element = document)
  {
    let fit_text_svgs = element.getElementsByClassName("fit-text");
    for (let i = 0; i < fit_text_svgs.length; i++) {
      let svg = fit_text_svgs[i]
      for (let j = 0; j < svg.children.length; j++) {
        let text_element = svg.children[j]
        let bbox = text_element.getBBox();
        let vb =
          [bbox.x,
           bbox.y,
           bbox.width,
           bbox.height].join(" ");
        svg.setAttribute("viewBox", vb);
      }
    }
  }
  root.select = function(translation_id,form_id)
  {
    document.getElementById("test_pick_" + form_id + "_input").value = translation_id;
    document.getElementById("test_pick_" + form_id + "_form").submit();
  }
  // window.onload = function()
  // {
  //   root.fit_all_text(document)
  // }
}).call(this);
