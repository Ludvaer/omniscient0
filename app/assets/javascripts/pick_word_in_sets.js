(function() {
  root = typeof exports !== "undefined" && exports !== null ? exports : this;
  recordManager = root.recordManager = {'classes':{}, 'objects':{}, 'rawObjects':{}};
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
    switch (name) {
      case 'PickWordInSet':
        klass = {
          'picked': 'Translation',
          'correct': 'Translation',
          'translation_set': 'TranslationSet'
         }
        break;
      case 'TranslationSet':
        klass = {
          'translation': 'Translation'
         }
        break;
      case 'Translation':
        klass = {
          'word': 'Word'
         }
        break;
      case 'Word':
        klass = {
         }
        break;
      default:
        console.log(`Sorry, we are out of ${name}.`);
    }
    classes[name] = klass;
    return klass;
  }
  root.classStructure = classStructure;

  function collectId(data, objectsToRequest) {
    structure = classStructure(data.className)
    objectCollections = recordManager.rawObjects
    Object.entries(structure).forEach(([field,className]) => {
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
    data.isPreloaded = false
    objectFromDict(recordManager.rawObjects, data.className)[data.id] = data;
    //objectFromDict(recordManager.rawObjects, data.className)[data.id] = data;
    console.log(`+++collecting ${data.className} : ${data.id} => [${Object.keys(objectFromDict(recordManager.rawObjects, data.className)).length}]`);
  }

  function fillId(data, previouslyRequested) {
    //console.log(`~~~filling ${data.className} : ${JSON.stringify(data)}`)
    structure = classStructure(data.className)
    objectCollections = previouslyRequested
    Object.entries(structure).forEach(([field,className]) => {
        objectsExist = objectFromDict(objectCollections, className)
        singleIdField = field + '_id'
        if (singleIdField in data) {
           id = data[singleIdField]
           if(!(id == null) && (id in objectsExist)) { data[field] = objectsExist[id]; }
        }
        multipleId = field + '_ids'
        if (multipleId in data) {
           let dataField = data[field + 's'] = []
           data[multipleId].forEach((id) => {
             if(!(id == null) && (id in objectsExist)) { dataField.push(objectsExist[id]); }
           });
        }
    })
    data.isPreloaded = true
    objectFromDict(recordManager.objects, data.className)[data.id] = data;
    //console.log(`+++filling ${data.className} : ${data.id} => [${Object.keys(objectFromDict(recordManager.objects, data.className)).length}]`);
  }

  root.collectId = collectId
  function arrayariseObjectsToRequest(objectsToRequest)
  {
     Object.entries(objectsToRequest).forEach(([className,idsToRequest]) => {
       objectsToRequest[className] = Object.entries(idsToRequest)
          .filter(([id,idsToRequest]) => idsToRequest)
          .map(([id,idsToRequest]) => id);
     });
  }
  root.arrayariseObjectsToRequest = arrayariseObjectsToRequest
  function preloadData(objectsToRequest, finishFunction, previouslyRequested={})
  {
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
        console.log(`>>> success loading data = ${JSON.stringify(data)}`);
        objectCollections = recordManager.rawObjects;
        objectsToRequest = {};
        Object.entries(data).forEach(([className,incomingObjects]) => {
          objectsRaw = objectFromDict(objectCollections, className)
          //console.log(`+++ ${className} => ${JSON.stringify(incomingObjects)}`);
          Object.entries(incomingObjects).forEach(([id,incomingObject]) => {
            incomingObject.className = className;
            console.log(`---collecting ${className} : ${id}`);
            collectId(incomingObject, objectsToRequest);
            objectFromDict(previouslyRequested, className)[id] = incomingObject;
          });
        });
        if (Object.values(objectsToRequest).some(a => a.length > 0))
        {
          arrayariseObjectsToRequest(objectsToRequest);
          console.log(`>>> data to request = ${JSON.stringify(objectsToRequest)}`);
          //preloadData(objectsToRequest);
          setTimeout(() =>{preloadData(objectsToRequest,finishFunction,previouslyRequested)}, 100);
        }
        else { //if all requested subobjects received  then iterate overthem
          Object.entries(previouslyRequested).forEach(([className,requestedObjects]) => {
            Object.entries(requestedObjects).forEach(([id,requestedObject]) => {
              //console.log(`---fill ${className} : ${id}`);
              requestedObject.className = className
              fillId(requestedObject, previouslyRequested); //and match id with loaded objects
            });
          });
          finishFunction();
        }
      }
    });
  }
  root.preloadData = preloadData

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
  root.select = function(translation_id,form_model)
  {
    form_model.picked_input.value = translation_id
    form_model.data.picked_id = translation_id
    submit_pick(form_model)
    //form.submit();
  }

  function submit_pick(form_model)
  {
    var data, method;
    data = {'pick_word_in_set[picked_id]':form_model.data.picked_id};
    method = 'PATCH';
    return $.ajax(form_model.form.getAttribute('action'), {
      type: method,
      dataType: 'json',
      data: data,
      error: function(jqXHR, textStatus, errorThrown) {
        alert("Saving progress failed.");
        //TODO: system for local keeping and retrying to save obj
        //with polite reminding that saving issues are here
      },
      success: function(data, textStatus, jqXHR) {
          // similar behavior as an HTTP redirect
          //window.location.replace("https://stackoverflow.com");
          // similar behavior as clicking on a link
          window.location.href = pick_word_in_set_url;
      }
    });
  }
  function fill_pick(form_model,data)
  {
    for (let j = 0; j < board.children.length; j++) {
      let element = svg.children[j]
      if(element.tagName == 'BUTTON')
      {
      }
    }
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
    picked_input = model.picked_input = null;
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
      if(child.tagName == 'BUTTON')
        { buttons.push(child); }
    }
    for (let j = 0; j < svg.children.length; j++)
    {
      let child = svg.children[j]
      if(child.tagName == 'TEXT')
        { svgText = model.svgText = child; }
    }
    for (let j = 0; j < form.children.length; j++)
    {
      let child = form.children[j]
      if(child.tagName == 'INPUT' && child.getAttribute("name") == "pick_word_in_set[picked_id]")
        { picked_input = model.picked_input = child; }
    }
    return model;
  }
  root.form_form_model_from = form_form_model_from;
}).call(this);
