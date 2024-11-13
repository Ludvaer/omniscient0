(function() {
  root = typeof exports !== "undefined" && exports !== null ? exports : this;
  //Objects which are already receive  stored in rawObjects {id:object}
  //Objects which have their dependancies loaded are stored in objects {id:object}
  //Type structure stored within classes {'TypeName':{'field_name':'ReferencedType'}}
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
    //id of abject which are already received are stored in rawObjects
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
  }

  function connectReferences(data, loadedObjectsTree) {
    //console.log(`~~~filling ${data.className} : ${JSON.stringify(data)}`)
    structure = classStructure(data.className)
    Object.entries(structure).forEach(([field,className]) => {
        objectsLoaded = objectFromDict(loadedObjectsTree, className)
        singleIdField = field + '_id'
        if (singleIdField in data) {
           id = data[singleIdField]
           if(!(id == null) && (id in objectsLoaded)) { data[field] = objectsLoaded[id]; }
        }
        multipleId = field + '_ids'
        if (multipleId in data) {
           let dataField = data[field + 's'] = []
           data[multipleId].forEach((id) => {
             if(!(id == null) && (id in objectsLoaded)) { dataField.push(objectsLoaded[id]); }
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
    console.log(`>>> success loading data = ${JSON.stringify(data)}`);
    objectCollections = recordManager.rawObjects;
    objectsToRequest = {};
    //preprocessing
    //ensure incoming objects ar registered as requested and save as raw
    Object.entries(data).forEach(([className,incomingObjects]) => {
      objectsRaw = objectFromDict(objectCollections, className)
      Object.entries(incomingObjects).forEach(([id,incomingObject]) => {
          //mark all incoming objects as already requested
          incomingObject.isPreloaded = false;
          incomingObject.className = className;
          objectFromDict(previouslyRequested, className)[id] = incomingObject;
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
    console.log(`>>> data to request = ${JSON.stringify(objectsToRequest)}`);
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
