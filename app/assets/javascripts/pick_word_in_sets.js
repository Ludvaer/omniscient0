(function() {
  let root = typeof exports !== "undefined" && exports !== null ? exports : this;
  //Objects which are already receive  stored in rawObjects {id:object}
  //Objects which have their dependancies loaded are stored in objects {id:object}
  //Type structure stored within classes {'TypeName':{'field_name':'ReferencedType'}}
  var system_fields = {'className':true,'isPreloaded':true}
  var recordManager = root.recordManager = {'classes':{}, 'objects':{}, 'rawObjects':{}};
  recordManager.classes = recordManager.objects['ClassModel'] = recordManager.rawObjects['ClassModel'] = {'ClassModel':{}};
  function objectFromDict(dict, key) {
    if (!(key in dict)){ dict[key] = { }; }
    return dict[key]
  }
  root.objectFromDict = objectFromDict;

  function classStructure(name)
  {
    let classes = recordManager.classes;
    if (name in classes) {
       return classes[name]
    }
    let klass = {};
    console.log(`Sorry, we are out of ${name}.`);
    classes[name] = klass;
    return klass;
  }
  root.classStructure = classStructure;

  function collectId(data, objectsToRequest) {
    // if(data.className == 'ClassModel') {
    //   Object.entries(data).forEach(([field,className]) => {
    //     if(!(className in recordManager.classes))
    //   }
    // }
    //TPDO: probably more reliable to use previously requested  and loaded objects
    structure = (data.className == 'ClassModel') ? data : classStructure(data.className)
    //id of abject which are already received are stored in rawObjects
    objectCollections = recordManager.rawObjects
    Object.entries(structure).forEach(([field,className]) => {
        if (field in system_fields) { return;}
        objectsExist = objectFromDict(objectCollections, className)
        objectsRequest = objectFromDict(objectsToRequest, className)
        singleIdField = field + '_id'
        if (singleIdField in data) {
           id = data[singleIdField]
           if(!(id == null) && !(id in objectsExist)) { objectsRequest[id] = true; }
        }
        multipleId = field + '_ids'
        if (multipleId in data) {
           data[multipleId].forEach((id) => {
             if(!(id == null) && !(id in objectsExist)) { objectsRequest[id] = true; }
           });
        }
    })
  }

  function connectReferences(data, loadedObjectsTree=recordManager.rawObjects) {
    //console.log(`~~~filling ${data.className} : ${JSON.stringify(data)}`)
    if(data.className == 'ClassModel') {
      return;
    }
    structure = classStructure(data.className)
    Object.entries(structure).forEach(([field,className]) => {
        if (field in system_fields) { return;}
        //new objects linked either from accumulated objects to be linked
        //or from olready fully loaded objects
        objectsLoaded = objectFromDict(loadedObjectsTree, className)
        objectsLoaded2 = objectFromDict(recordManager.objects, className)
        singleIdField = field + '_id'
        if (singleIdField in data) {
           id = data[singleIdField]
           if(!(id == null)) {
             if (id in objectsLoaded) { data[field] = objectsLoaded[id]; }
             else if (id in objectsLoaded2) { data[field] = objectsLoaded2[id]; }
             else { console.log(`??? lost ${singleIdField}: ${className} for ${data.className}[${data.id}]`) }
           }
        }
        multipleId = field + '_ids'
        if (multipleId in data) {
           let dataField = data[field + 's'] = []
           data[multipleId].forEach((id) => {
             if(!(id == null)) {
                if (id in objectsLoaded) { dataField.push(objectsLoaded[id]); }
                else if (id in objectsLoaded2) { dataField.push(objectsLoaded2[id]); }
                else { console.log(`??? lost ${singleIdField}: ${className} for ${data.className}[${data.id}]`) }
             }
           });
        }
    })
  }

  root.collectId = collectId
  function arrayariseObjectsToRequest(objectsToRequest)
  {
     Object.entries(objectsToRequest).forEach(([className,idsToRequest]) => {
       objectsToRequest[className] = Object.entries(idsToRequest)
          //.filter(([id,idsToRequest]) => idsToRequest)
          .map(([id,idsToRequest]) => id);
     });
  }
  root.arrayariseObjectsToRequest = arrayariseObjectsToRequest
  function receiveData(data, finishFunction, previouslyRequested={}) {
    //console.log(`>>> success loading data = ${JSON.stringify(data)}`);
    console.log(`>>> success loading data = ${data}`);
    objectCollections = recordManager.rawObjects;
    objectsToRequest = {};
    //preprocessing
    //ensure incoming objects ar registered as requested and save as raw
    Object.entries(data).forEach(([className,incomingObjects]) => {
      objectsRaw = objectFromDict(objectCollections, className)
      objectsRequested = objectFromDict(previouslyRequested, className)
      Object.entries(incomingObjects).forEach(([id,incomingObject]) => {
          //mark all incoming objects as already requested
          if(className === "ClassModel") {

          }
          incomingObject.isPreloaded = false;
          incomingObject.className = className;
          objectsRequested[id] = incomingObject;
          objectsRaw[id] = incomingObject;
      });
    });
    //building request
    //collect missing ids from incoming object ignoring already loaded ids
    Object.entries(data).forEach(([className,incomingObjects]) => {
      Object.entries(incomingObjects).forEach(([id,incomingObject]) => {
        collectId(incomingObject, objectsToRequest);
      });
    });
    arrayariseObjectsToRequest(objectsToRequest);
    //console.log(`>>> data to request = ${JSON.stringify(objectsToRequest)}`);
    console.log(`>>> data to request = ${objectsToRequest}`);
    if (Object.values(objectsToRequest).some(a => a.length > 0))
    {
      //TODO: make timeout only in dev environment (for infinite recursion safe debug)
      setTimeout(() =>{preloadData(objectsToRequest,finishFunction,previouslyRequested)}, 100);
    }
    else { //postprocessing if all object tree is loaded
      //if all requested objects received then match all references objs
      Object.entries(previouslyRequested).forEach(([className,requestedObjects]) => {
        Object.entries(requestedObjects).forEach(([id,requestedObject]) => {
          connectReferences(requestedObject, previouslyRequested);
        });
      });
      //only after references for all objs are connected we can save them in fully loaded
      Object.entries(previouslyRequested).forEach(([className,requestedObjects]) => {
        objectsById = objectFromDict(recordManager.objects, className)
        Object.entries(requestedObjects).forEach(([id,requestedObject]) => {
          requestedObject.isPreloaded = true;
          objectsById[id] = requestedObject;
        });
      });
      finishFunction(); //proceed to action that required loaded objects
    }
  }
  root.receiveData = receiveData
  function preloadData(objectsToRequest, finishFunction, previouslyRequested={})
  {
    //check if preload of unknown classes is requested
    requestedClasses = {}
    if ('ClassModel' in objectsToRequest) {
      objectsToRequest['ClassModel'].forEach((name) => requestedClasses[name] = true);
    }
    Object.entries(objectsToRequest).forEach(([className,requestedObjects]) => {
      if(!((className in recordManager.classes) || (className in requestedClasses))) {
        if (!('ClassModel' in objectsToRequest)) { objectsToRequest['ClassModel'] = []; }
        objectsToRequest['ClassModel'].push(className);
      }
    });
    //objectsToRequest as {'TypeName':[id]}
    //finishFunction to call after all objects and references objs are in replace
    //previouslyRequested to keep track of objects loaded over recursive calls
    return $.ajax(root.data_preload_url, {
      type: 'GET',
      dataType: 'json',
      data: {"data": objectsToRequest},
      error: function(jqXHR, textStatus, errorThrown) {
        alert("Preloading data failed.");
        //TODO: system for local keeping and retrying to save obj
        //with polite reminding that saving issues are here
      },
      success: function(data, textStatus, jqXHR) {
        receiveData(data, finishFunction, previouslyRequested)
      }
    });
  }
  root.preloadData = preloadData

  root.fit_all_text = function (element = document)
  {
    let fit_text_svgs = element.getElementsByClassName("fit-text");
    if (element.className == "fit-text") {
      fit_text_svgs.push(element)
    }
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
  function select(translation_id,form_model)
  {
    //form_model.picked_input.value = translation_id
    form_model.data.picked_id = translation_id
    recordManager.objects[form_model.data.className][form_model.data.id] = form_model.data
    connectReferences(form_model.data)
    //submit_pick(form_model, () => {window.location.replace(pick_word_in_set_url);})
    //submit_pick(form_model {return Turbolinks.visit(pick_word_in_set_url);})
    submit_pick(form_model,()=>{});
    //todo correcly would be pass url in linkable object
    history.pushState({id:form_model.data.id}, "",
          `${pick_word_in_sets_url}/${form_model.data.id}?n=${preload_queue_target_size}`)
    fill_form(form_model)
    form_model.nextButton.hidden = false;
          console.log(`nextButton.hidden = false`);
    //form.submit();
  }
  root.select = select

  function scrollToElementCenter(element) {
      if (!element) return;

      // Get the element's bounding rectangle
      const rect = element.getBoundingClientRect();

      if (rect.top >= 0 &&
      rect.left >= 0 &&
      rect.bottom <= window.innerHeight &&
      rect.right <= window.innerWidth) {
          return;
      } // Element is already completely within the viewport
      // Calculate the center position of the element relative to the viewport
      const elementCenterX = rect.left + rect.width / 2;
      const elementCenterY = rect.top + rect.height / 2;

      // Calculate the scroll offsets needed to center the element
      const scrollX = window.scrollX + elementCenterX - window.innerWidth / 2;
      const scrollY = window.scrollY + elementCenterY - window.innerHeight / 2;

      // Smoothly scroll to the calculated position
      window.scrollTo({
          top: scrollY,
          left: scrollX,
          behavior: 'smooth'
      });
  }

  function moveNewPick(form_model, id = null) {
    form_model.nextButton.hidden = true;
    let tests = recordManager.objects.PickWordInSet;
    let unfilledTests = Object.values(tests).filter((p) => p.picked_id == null)
    let filled = false;
    if(unfilledTests.length >= 1 || (id != null)) {
      form_model.data = id == null ? unfilledTests[0] : recordManager.objects.PickWordInSet[id];
      fill_form(form_model)
      history.pushState({id:form_model.data.id}, "", pick_word_in_sets_url + "/" + form_model.data.id + "/edit")
      filled = true
      scrollToElementCenter(form_model.root);
      //filter out filled pick_word_in_set???
    }
    if (unfilledTests.length < root.preload_queue_target_size) {
      postNew(filled ? null : form_model); //pass model to be  filled with new picks if needed
    }
  }
  function postNew(form_model = null) {
    return $.ajax(pick_word_in_sets_url, {
      type: 'POST',
      dataType: 'json',
      data: {n:preload_queue_target_size},
      error: function(jqXHR, textStatus, errorThrown) {
        alert("Loadin new progress failed.");
        //TODO: system for local keeping and retrying to save obj
        //with polite reminding that saving issues are here
      },
      success: function(data, textStatus, jqXHR) {
          console.log(`$$$ data loaded`);
          receiveData(data,() =>
          {
            if(form_model != null) //passed model meant to use it to fill with new data
            {
              moveNewPick(form_model);
            }
          })
          //root.dataFromNewPick = data;
          //return Turbolinks.visit(pick_word_in_sets_url + "/" + data.id + "/edit");
          // similar behavior as an HTTP redirect
          //window.location.replace(pick_word_in_set_url);
          // similar behavior as clicking on a link
          //window.location.href = pick_word_in_set_url;
          //TODO: understand what exacyly is the differnece
      }
    });
  }
  root.moveNewPick = moveNewPick;
  root.postNew = postNew;
  function fill_form(form_model)
  {
    console.log(`%%% filling form`);
    if(form_model.data == null || form_model.data.id == null)
    {
      Array.from(form_model.optionBoard.children).forEach((item) => {
        item.hidden = true;
      });
      //form_model.optionBoard.hidden = true;
      form_model.nextButton.hidden = false;
      form_model.nextButton.className = 'btn-next'
      return;
    }
    Array.from(form_model.optionBoard.children).forEach((item) => {
      item.hidden = false;
    });
    form_model.optionBoard.hidden = false;
    pick_word_in_set = form_model.data;
    let translations = pick_word_in_set.translation_set.translations
    let length = form_model.buttons.length;
    let isCorrect = form_model.isCorrect() //pick_word_in_set.correct.word.id == pick_word_in_set.picked.word.id
    form_model.commentWord.innerHTML = form_model.data.additional.translation;
    for (let j = 0; j < length; j++)
    {
      if(j > buttons.length) { break; }
      let button = form_model.buttons[j];
      let translation = j < translations.length? translations[j] :  {};
      if(button == form_model.dunnoButton) { translation ={'id': 0, 'translation':dunnoText};}
      if(button == form_model.nextButton) { translation ={'id': -1, 'translation':nextText};}
      let prefix = ""
      let className="enabled_option_btn"
      if(button != form_model.nextButton) {
        button.onclick = (()=>{});
        button.hidden = false;
      }
      if (pick_word_in_set.picked_id == null) {
        className="enabled_option_btn"
        if(button != form_model.nextButton) {
            button.onclick = (() =>{select(translation.id,form_model)});
        }
        prefix = [7,8,9,4,5,6,1,2,3,0,'enter'][j] + ":";
        //console.log(`% ${j} enabled_option_btn`);
      }
      else if (pick_word_in_set.picked_id == translation.id && isCorrect) {
        className="disabled_option_btn_yes"
        prefix = "✔";
        //console.log(`% ${j} disabled_option_btn_yes`);
      } else if (pick_word_in_set.picked_id == translation.id) {
        className="disabled_option_btn_no";
        prefix = "❌";
        //console.log(`% ${j} enabled_option_btn`);
      } else if (form_model.isCorrectTransaction(translation)) {
        className="disabled_option_btn_this";
        prefix = "🢂";
        //console.log(`% ${j} disabled_option_btn_this`);
      } else {
        className="disabled_option_btn";
        //console.log(`% ${j} disabled_option_btn`);
      }
      if(button != form_model.nextButton)
      {
         button.className = className;
         button.optionMarker.innerHTML = prefix;
         if(button == form_model.dunnoButton) {button.classList.add("btn-dunno");}
         else { button.optionText.innerHTML = translation.translation; }
      }
    }
    form_model.svgText.innerHTML = pick_word_in_set.correct.word.spelling;
    fit_all_text(form_model.root);
    if(pick_word_in_set.picked_id == null)
    {
      console.log(`nextButton.hidden = true`);
      form_model.nextButton.hidden = true;
      form_model.nextButton.className = ''
      //form_model.nextButton.style.display = 'hidden'
    }
    else
    {
      console.log(`nextButton.hidden = false`);
      form_model.nextButton.hidden = false;
      form_model.nextButton.className = 'btn-next'
    }
  }
  root.fill_form = fill_form

  function submit_pick(form_model, successFunction)
  {
    var data, method;
    data = {'pick_word_in_set[picked_id]':form_model.data.picked_id};
    method = 'PATCH';
    return $.ajax(pick_word_in_sets_url +'/' + form_model.data.id, {
      type: method,
      dataType: 'json',
      data: data,
      error: function(jqXHR, textStatus, errorThrown) {
        alert("Saving progress failed.");
        //TODO: system for local keeping and retrying to save obj
        //with polite reminding that saving issues are here
      },
      success: function(data, textStatus, jqXHR) {
          successFunction();
          // similar behavior as an HTTP redirect
          //window.location.replace(pick_word_in_set_url);
          // similar behavior as clicking on a link
          //window.location.href = pick_word_in_set_url;
          //TODO: understand what exacyly is the differnece
      }
    });
  }


  // window.onload = function()
  // {
  //   root.fit_all_text(document)
  // }
  function form_form_model_from(pick_div)
  {
    let model = {};
    model.root = pick_div;
    optionBoard = model.optionBoard = null;
    form = model.form = null;
    svg = model.svg = null;
    buttons = model.buttons = [];
    svgText = model.svgText = null;
    model.commentWord = model.root.querySelector('.comment-word');
    // nextButton = model.nextButton = model.root.querySelector('.btn-next');
    // model.dunnoButton = model.root.querySelector('.btn-dunno');
    //picked_input = model.picked_input = null;
    for (let j = 0; j < pick_div.children.length; j++)
    {
      let child = pick_div.children[j]
      if(child.tagName == 'DIV' && child.className == 'optionboard')
        { optionBoard = model.optionBoard = child; }
      if(child.tagName == 'FORM')
        { form = model.form = child; }
    }
    for (let j = 0; j < optionBoard.children.length; j++)
    {
      let child = optionBoard.children[j]
      if(child.tagName == 'svg')
        { svg = model.svg = child; }
      if(child.tagName == 'BUTTON') {
        buttons.push(child);
        child.optionText = child.querySelector('.option-text');
        child.optionMarker = child.querySelector('.option-marker');
      }
    }
    for (let j = 0; j < svg.children.length; j++)
    {
      let child = svg.children[j]
      if(child.tagName == 'text')
        { svgText = model.svgText = child; }
    }
    nextButton = model.nextButton = buttons[buttons.length-1];
    model.dunnoButton = buttons[buttons.length-2];
    // for (let j = 0; j < form.children.length; j++)
    // {
    //   let child = form.children[j]
    //   if(child.tagName == 'INPUT' && child.getAttribute("name") == "pick_word_in_set[picked_id]")
    //     { picked_input = model.picked_input = child; }
    // }

     buttons.forEach(btn => {
      btn.addEventListener('mouseenter', () => {
        model.buttons.forEach(b => {b != btn? b.blur() : b.focus(); });
        // Automatically focus the button on hover and unfocus every one else
      });
      btn.addEventListener('mouseleave', () => {    btn.blur(); });
     });

     model.isCorrectTransaction = ((transaction) => {
       return model.data.correct_id == transaction.id;
     });
     model.isCorrect = (() => {
       return model.data.correct_id == model.data.picked_id;
     });
    return model;
  }
  root.form_form_model_from = form_form_model_from;
  var declared;
  try {
    root.pick_model_inits = root.pick_model_inits? root.pick_model_inits : [];
    declared = true;
  } catch(e) {
    declared = false;
  }
  var pick_model_inits = declared ? pick_model_inits : [];
  root.pick_model_inits.forEach( (i) => {i();})
}).call(this);
