
(function() {
  root = typeof exports !== "undefined" && exports !== null ? exports : this;

  //root.gameboard = document.getElementById('gameboard');
  root.table_size = 0;
  root.table_length = table_size*table_size;
  root.game_status = 0;
  root.mistakes = 0;
  root.suffle_number = BigInt(0);
  root.startTime = null;
  root.endTime = null;

  function play()
  {

    root.table_size = 3;
    root.game_status = 0;
    root.table_length = table_size*table_size;
    root.mistakes = 0;
    root.suffle_number = fill_table();
    root.startTime = performance.now();
  }
  show_start_button = function()
  {
    root.gameboard = document.getElementById('gameboard');
    root.gameboard.innerHTML = "";
    var start_button = document.createElement("button");
    //start_button.id = "start_button"
    start_button.innerHTML = "Start"
    start_button.onclick = play;
    start_button.className = "btn";

    root.gameboard.appendChild(start_button);
  }
  root.show_start_button = show_start_button;

  function shuffle(array) {  // http://stackoverflow.com/questions/2450954/how-to-randomize-shuffle-a-javascript-array
    let currentIndex = array.length,  randomIndex;
    let number = BigInt(0);
    var mult = BigInt(1);
    // While there remain elements to shuffle.
    while (currentIndex != 0) {

      // Pick a remaining element.
      randomIndex = Math.floor(Math.random() * currentIndex);
      number +=  BigInt(randomIndex)*mult;
      mult *= BigInt(currentIndex +1);
      currentIndex--;

      // And swap it with the current element.
      [array[currentIndex], array[randomIndex]] = [
        array[randomIndex], array[currentIndex]];
      }

      return [array,number];
    }
    function factorialize(num)
    {
      var result = BigInt(num);
      if (num === 0 || num === 1)
      return 1;
      while (num > 1) {
        num--;
        result *= BigInt(num);
      }
      return result;
    }
    function click_cell(n, btn)
    {
      if ( n == game_status + 1)
      {

        btn.style.display = "none";
        ++game_status;
        if(game_status >= table_length)
        {
          form = document.getElementById("shulte_form");
          endTime = performance.now();
          document.getElementById('time').value  = Math.round(endTime - startTime);
          document.getElementById('size').value   = table_size;
          document.getElementById('mistakes').value   = mistakes;
          document.getElementById('shuffle').value   = suffle_number;
          sendShulte();
          show_start_button();
          //finisj game
        }

      }
      else {
        ++mistakes;
      }

    }

    function fill_table()
    {


      root.gameboard.innerHTML = "";
      let table = document.createElement('table');

      root.gameboard.appendChild(table);
      //let thead = document.createElement('thead');
      //let tbody = document.createElement('tbody');
      //table.appendChild(thead);
      //table.appendChild(tbody);

      let size = table_size;
      let length = table_length;
      var fontsize = length > 99 ? 30/size : 40/size;
      table.style.fontSize = "24px"//fontsize + "vmin";

      //var shuffleCount = factorialize(length)
      let numbers =[]
      for (var i = 0; i < length; i++)
      {
        numbers[i] = i+1;
      }
      let suffle_number = shuffle(numbers)[1]
      for (var i = 0; i < size; i++)
      {

        let row =  document.createElement('tr');
        table.appendChild(row);
        row.style.height = (100.0/size)+"%";
        for (var j = 0; j < size; j++)
        {
          let cell =  document.createElement('td');
          cell.style.width = (100.0/size)+"%";
          //var cellButton =  document.createElement('td');
          //cell.innerHTML = numbers[i*size+j];
          row.appendChild(cell);
          let btn = document.createElement("button");
          cell.appendChild(btn);
          let number = numbers[i*size+j];
          btn.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" style="width: 100%; height: 100%; margin-left: auto; margin-right: auto;"><text dominant-baseline="middle" text-anchor="middle">a</text></svg>'
          let svg = btn.children[0];
          let text_element = svg.children[0];
          text_element.textContent = number;
          let bbox = text_element.getBBox();
          let vb =
            [bbox.x,
             bbox.y,
             bbox.width,
             bbox.height].join(" ");
          svg.setAttribute("viewBox", vb);

          btn.onclick = function () { click_cell(number,btn); };
          //btn.style.fontSize = fontsize + "vmin";

        }
      }
      return suffle_number;
    }

    serializeForm = function(form) {
      var hash, i, item, len, ref;
      hash = {};
      ref = form.serializeArray();
      for (i = 0, len = ref.length; i < len; i++) {
        item = ref[i];
        hash[item.name] = item.value;
      }
      return hash;
    };

    root.sendShulte = function() {
      var data, method;
      data = serializeForm($('form'));
      method = 'post';
      if ($('input[name="_method"]').val()) {
        method = $('input[name="_method"]').val();
      }
      return $.ajax($('form').attr('action'), {
        type: method,
        dataType: 'json',
        data: data,
        error: function(jqXHR, textStatus, errorThrown) {
          alert("Ajax request failed");
          return show_start_button();
        },
        success: function(data, textStatus, jqXHR) {
          return $("#shulte-save-response").html(data.html);
        }
      });
    }
  }).call(this);
