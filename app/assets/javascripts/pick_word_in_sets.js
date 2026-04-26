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
  function receiveData(data, finishFunction, previouslyRequested={},  prevObjectsToRequest = {} ) {
    //console.log(`>>> success loading data = ${JSON.stringify(data)}`);
    console.log(`>>> success loading data = ${JSON.stringify(Object.fromEntries(Object.entries(data).map((a) => [a[0],Object.keys(a[1])])))}`);
    objectCollections = recordManager.rawObjects;
    objectsToRequest = {}
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

    unreceived = 0;
    received = 0;
    // check requested objects for missing
    Object.entries(prevObjectsToRequest).forEach(([className,requestedIds]) => {
      objectsRaw = objectFromDict(objectCollections, className)
      objectsRequested = objectFromDict(previouslyRequested, className)
      toRequest = objectFromDict(objectsToRequest, className)
      requestedIds.forEach((id, i) => {
        if(!(objectsRaw[id] && objectsRequested[id])) {
          toRequest[id] = true;
          unreceived+=1;
        } else {received +=1;}
      });
    });
    console.log(`>>> unreceived = ${unreceived}; and received = ${received}`);
    //building request
    //collect missing ids from incoming object ignoring already loaded ids
    Object.entries(data).forEach(([className,incomingObjects]) => {
      Object.entries(incomingObjects).forEach(([id,incomingObject]) => {
        collectId(incomingObject, objectsToRequest);
      });
    });


    arrayariseObjectsToRequest(objectsToRequest);
    //console.log(`>>> data to request = ${JSON.stringify(objectsToRequest)}`);
    console.log(`>>> data to request = ${JSON.stringify(Object.fromEntries(Object.entries(objectsToRequest).map((a) => [a[0],(a[1])])))}`);

    if (Object.values(objectsToRequest).some(a => a.length > 0))
    {
      //TODO: make timeout only in dev environment (for infinite recursion safe debug)
      setTimeout(() =>{preloadData(objectsToRequest,finishFunction,previouslyRequested)}, 100);
    }
    else { //postprocessing if all object tree is loaded
      //if all requested objects received then match all references objs
      if('ClassModel' in previouslyRequested) {
        Object.entries(previouslyRequested['ClassModel']).forEach((name, structure) => {
          recordManager.classes[name] = structure;
        });
      }
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
    var delayedObjects = {}
    while (JSON.stringify(objectsToRequest).length > 1500) {
        Object.entries(objectsToRequest).forEach(([className,requestedObjects]) => {
          if(objectsToRequest != 'ClassModel') {
            objectsToRequest[className] = requestedObjects.slice(0,requestedObjects.length/2)
            delayedObjects[className] = requestedObjects;//.slice(requestedObjects.length/2, requestedObjects.length)
          }
        });
    }
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
        receiveData(data, finishFunction, previouslyRequested, delayedObjects)
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
          `${pick_word_in_sets_url}/${form_model.data.id}?`
          + (new URLSearchParams(form_model.params)).toString())
    fill_form(form_model)
    form_model.showNextButton();
  }
  root.select = select

  function scrollToElementCenter(element) {
      if (!element) return;

      // Get the element's bounding rectangle
      const rect = element.getBoundingClientRect();

      let scrollY = null;
      if (rect.top < 0 + 1) {
        if (rect.height < window.innerHeight + 1) {
          console.log(`||| scroll top top`);
          scrollY = window.scrollY + rect.top;
        } else if (rect.top + rect.height < window.innerHeight + 1) {
          console.log(`||| scroll top bot`);
          scrollY = window.scrollY + rect.top + rect.height - window.innerHeight;
        }
      }
      if (rect.top + rect.height > window.innerHeight - 1) {
        if (rect.height < window.innerHeight + 1) {
          console.log(`||| scroll bot bot`);
          scrollY = window.scrollY + rect.top + rect.height - window.innerHeight;
        } else if (rect.top > 0 - 1) {
          console.log(`||| scroll bot top`);
          scrollY = window.scrollY + rect.top;
        }
      }

      if(scrollY != null) {
          console.log(`||| scroll go`);
        window.scrollTo({
            top: scrollY,
            left: window.scrollX,
            behavior: 'smooth'
        });
      }
//       scrollY = window.scrollY + elementCenterY - window.innerHeight / 2;
  }

  function moveNewPick(form_model, id = null) {
    console.log(`%%% moving templateId = ${form_model.templateId }`);
    form_model.buttons.forEach((b) => { b.blur(); });
    form_model.hideNextButton();
    let tests = recordManager.objects.PickWordInSet;
    let unfilledTests = (tests && form_model.templateId > 0)
      ? Object.values(tests).filter((p) => p.picked_id == null && p.template_id === form_model.templateId)
      : []
    let filled = false;
    if(unfilledTests.length >= 1 || (id != null)) {
      form_model.data = id == null ? unfilledTests[0] : recordManager.objects.PickWordInSet[id];
      fill_form(form_model)
      if(form_model.data.picked_id == null){
        history.pushState({id:form_model.data.id}, "", pick_word_in_sets_url + "/" + form_model.data.id + "/edit?"
              + (new URLSearchParams(form_model.params)).toString())
      } else {
        history.pushState({id:form_model.data.id}, "",
              `${pick_word_in_sets_url}/${form_model.data.id}?`
              + (new URLSearchParams(form_model.params)).toString())
      }
      filled = true
      scrollToElementCenter(form_model.root);
      //filter out filled pick_word_in_set???
    }
    if (unfilledTests.length < form_model.pickWordInSetN) {
      postNew(form_model, !filled); //pass model to be  filled with new picks if needed
    }
  }
  function postNew(form_model, needMove) {
    return $.ajax(pick_word_in_sets_url, {
      type: 'POST',
      dataType: 'json',
      data: Object.assign({}, form_model.params, {'recursive': needMove}),
      error: function(jqXHR, textStatus, errorThrown) {
        alert("Loading new failed.");
        //TODO: system for local keeping and retrying to save obj
        //with polite reminding that saving issues are here
      },
      success: function(data, textStatus, jqXHR) {
          console.log(`$$$ data loaded`);
          form_model.templateId = data.template_id
          receiveData(data.data,() =>
          {
            if(needMove) //passed model meant to use it to fill with new data
            {
              moveNewPick(form_model);
            }
          })
      }
    });
  }
  root.moveNewPick = moveNewPick;
  root.postNew = postNew;
  const markerSet3 = ['','','','','','','','','','','']
  const markerSet2 = ['q','w','e','a','s','d','z','x','c','\\','⌴']
  const markerSet1 = ['7','8','9','4','5','6','1','2','3','0','enter']
  const markerSets = [markerSet1,markerSet2,markerSet3]
  function getRandomInt(max) {
    return Math.floor(Math.random() * max);
  }

  function graphemeSplit(str) {
    const segmenter = new Intl.Segmenter("en", {granularity: 'grapheme'});
    const segitr = segmenter.segment(str);
    return Array.from(segitr, ({segment}) => segment);
  }
  function fill_form(form_model)
  {
    console.log(`%%% filling form`);
    if(form_model.data == null || form_model.data.id == null)
    {
      Array.from(form_model.optionBoard.children).forEach((item) => {
        if (item != form_model.nextButton) item.hidden = true;
      });
      //form_model.optionBoard.hidden = true;
      form_model.showNextButton();
      return;
    }
    Array.from(form_model.optionBoard.children).forEach((item) => {
      item.hidden = false;
    });
    form_model.optionBoard.hidden = false;
    let length = form_model.buttons.length;
    let isCorrect = form_model.isCorrect();
    let isAnswered = form_model.isAnswered();
    pick_word_in_set = form_model.data;
    correctTranslation = pick_word_in_set.correct
    correctWord = correctTranslation.word
    allTranslations = form_model.data.translation_set.translations
    sourceDialectId = form_model.data.correct.translation_dialect_id;
    targetDialectId = form_model.data.template.direction.target_dialect_id;
    optionDialectId = form_model.data.template.direction.option_dialect_id;
    displayDialectNames = pick_word_in_set.template.direction.display_dialects.map((d)=>d.name)
    displayDialectIds = pick_word_in_set.template.direction.display_dialects.map((d)=>d.id)
    console.log(`${JSON.stringify(displayDialectIds)} displayDialectIds`);
    mainDisplayDialectId =
        displayDialectIds.includes(targetDialectId) ? targetDialectId
        : (displayDialectIds[0]);
    console.log(`${JSON.stringify(mainDisplayDialectId)} mainDisplayDialectId`);
    if(isAnswered) {
      displayDialectIds = unique(displayDialectIds.concat(targetDialectId).concat(allTranslations.map((t) => t.translation_dialect.id))).filter((id) => id != optionDialectId)
    }
    console.log(`${JSON.stringify(displayDialectIds)} displayDialectIds`);
    addDisplayDialectId = displayDialectIds.filter((id) => id != mainDisplayDialectId)[0]
    console.log(`${JSON.stringify(addDisplayDialectId)} addDisplayDialectId`);
    let wordIds = [...new Set(allTranslations.map((t) => t.word.id))]; //unique words idsToRequest
    let translations = wordIds.map((id) =>
        allTranslations.filter((t) => t.word.id == id && t.translation_dialect_id == sourceDialectId)[0]);
    translations.sort((a,b) => {
      let d = (b.translation.length - a.translation.length);
      return d == 0 ? a.id - b.id : d;
    })
    let suffix = ' ' +  (pick_word_in_set.correct.suffix ?? '');
    additionalTranslation = addDisplayDialectId == targetDialectId  ? correctWord.spelling
        : allTranslations.filter((t) => t.word.id == correctWord.id && t.translation_dialect_id == addDisplayDialectId)[0]?.translation;

    console.log(`${JSON.stringify(additionalTranslation)} additionalTranslation`);
    if (additionalTranslation) {
      form_model.data.additional_translation = additionalTranslation
      if(addDisplayDialectId != sourceDialectId)
      {
        form_model.data.additional_translation += suffix;
      }
    } else {
      form_model.data.additional_translation = ''
    }
    if(mainDisplayDialectId == targetDialectId)
    {
      form_model.data.mainTranslation = correctWord.spelling;
    } else {
      form_model.data.mainTranslation = allTranslations.filter((t) => t.word.id == correctWord.id && t.translation_dialect_id == mainDisplayDialectId)[0]?.translation
    }
      console.log(`${JSON.stringify(form_model.data.mainTranslation)} mainTranslation`);

    if(mainDisplayDialectId != sourceDialectId)
    {
      form_model.data.mainTranslation += suffix;
    }

    form_model.commentWord.innerHTML = form_model.data.additional_translation;
    form_model.cornerNote.innerHTML = pick_word_in_set.correct.word.rank
    let correctKanji = []; //TODO: make japanese specific code separate from general pick word in set code
    let correctCharArray = [];
    let correctKanjiIndexes = [];
    let allIncorrectKanji = translations.filter((tr) => tr != form_model.data.correct && tr &&  tr.word)
        .flatMap((tr) => graphemeSplit(tr.word.spelling).filter((ch)=>wanakana.isKanji(ch) && ch != '々'));

        if(mainDisplayDialectId == sourceDialectId) {
           form_model.svgText.innerHTML = form_model.data.additional_translation;
           form_model.commentWord.innerHTML = form_model.data.mainTranslation;//pick_word_in_set.correct.translation;
         }
         else {
           form_model.svgText.innerHTML = form_model.data.mainTranslation;
           form_model.commentWord.innerHTML = form_model.data.additional_translation;//pick_word_in_set.correct.translation;

         }

    if (optionDialectId == targetDialectId && displayDialectNames.includes('kana')) {
      //form_model.svgText.innerHTML = form_model.data.mainTranslation

      correctCharArray = graphemeSplit(pick_word_in_set.correct.word.spelling + suffix);
      //wanakana.tokenize(pick_word_in_set.correct.word.spelling);
      for (let j = 0; j < correctCharArray.length; j++) {
        if(wanakana.isKanji(correctCharArray[j]) && correctCharArray[j] != '々') {
          correctKanjiIndexes.push(j); //collect indexes of kanji
        }
      }
      correctKanji = correctKanjiIndexes.map((i)=>correctCharArray[i]);
    }
    if(!('markerSet' in form_model)  || form_model.markerSet == null || form_model.data.picked_id == null)
      {form_model.markerSet = markerSets[getRandomInt(markerSets.length)];}
    markerSet = form_model.markerSet;
    for (let j = 0; j < length; j++)
    {
      if(j > form_model.buttons.length) { break; }
      let button = form_model.buttons[j];
      let translation = j < translations.length? translations[j] :  {'translation':'',word:{'id':0,'spelling':''}};
      if (translation.word.id === form_model.data.correct.word.id) { translation = form_model.data.correct; }
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
            button.onclick = (() =>{
              //console.log(`%%% clicking`);
              if(button === button?.contentWindow?.document?.activeElement || form_model.lastSelected === button )
                {select(translation.id,form_model);form_model.lastSelected = false;}
              else {
                form_model.lastSelected = button;
                form_model.buttons.forEach((b) => { b == button ? b.focus() : b.blur(); });
              }
            });
        }
        prefix = markerSet[j];// + ":";
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
         else {
           if (optionDialectId == translation.translation_dialect_id) {
             button.optionText.innerHTML = translation.translation + (optionDialectId == sourceDialectId ? '' : suffix);
           } else if (optionDialectId == translation.word.dialect_id) {
             // console.log(`% map ${correctKanji.length}  (${optionDialectId} == ${targetDialectId}) to ${translation.word.spelling}`);
             if(correctKanji.length > 0 && optionDialectId == targetDialectId)
             {
               // console.log(`% map ${correctKanji} eto ${translation.word.spelling}`);
               kanji = graphemeSplit(translation.word.spelling).filter((ch)=>wanakana.isKanji(ch) && ch != '々');
               while (kanji.length < correctKanji.length) {
                 kanji.push(allIncorrectKanji[(j + kanji.length + 1)%allIncorrectKanji.length]);
               }
               charArray = correctCharArray.slice(); //clone chars form correct answer
               for (let k = 0; k < correctKanji.length; k++) {
                 charArray[correctKanjiIndexes[k]] = kanji[k]; // substitute for wrong kanji
               }
               button.optionText.innerHTML =  charArray.join('');
             }
             else {
               button.optionText.innerHTML = translation.word.spelling + suffix;
             }
           } else {
             //button.optionText.innerHTML = translation.additional.translation;
             option_translation = allTranslations
                .filter((t) => t.word.id == translation.word.id && t.word.dialect_id == targetDialectId && t.translation_dialect_id == optionDialectId)[0];
             button.optionText.innerHTML = option_translation ? option_translation.translation + suffix : ('(?)'+ translation.translation);
           }
         }
      }
    }
    fit_all_text(form_model.root);
    form_model.nextButton.optionMarker.innerHTML = markerSet[10];
    if(pick_word_in_set.picked_id == null)
    {
      //form_model.showConfirmButton();
      form_model.hideNextButton();
    }
    else
    {

      form_model.showNextButton();
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
  function form_form_model_from(pick_div) //TODO: i really need to rewrite from model as proper class
  {
    const model = {};
    model.root = pick_div;
    let optionBoard = model.optionBoard = null;
    let form = model.form = null;
    let svg = model.svg = null;
    const buttons = model.buttons = [];
    let svgText = model.svgText = null;
    model.commentWord = model.root.querySelector('.comment-word');
    model.cornerNote = model.root.querySelector('.corner-note');

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
    const nextButton = model.nextButton = buttons[buttons.length-1];
    nextButton.className = 'btn-next';
    model.dunnoButton = buttons[buttons.length-2];
    // for (let j = 0; j < form.children.length; j++)
    // {
    //   let child = form.children[j]
    //   if(child.tagName == 'INPUT' && child.getAttribute("name") == "pick_word_in_set[picked_id]")
    //     { picked_input = model.picked_input = child; }
    // }
    model.confirm = () => {
         console.log(`%%% confirming`);
         model.buttons.forEach(b => {
             if(b === b?.contentWindow?.document?.activeElement && b != nextButton)
               { b.click(); model.lastKeyedIndex= false; }
         });
         if(model.lastSelected)
         {
           model.lastSelected.click();
         }
    };
     buttons.forEach(btn => {
      btn.addEventListener('mouseenter', () => {
        if( nextButton.isConfirm) {return;}
        model.buttons.forEach(b => {b != btn? b.blur() : (model.lastSelected = b).focus(); });
        if('data' in model && model.data.picked_id == null && btn != nextButton) { model.hideNextButton(); }
        // Automatically focus the button on hover and unfocus every one else
      });
      btn.addEventListener('mouseleave', () => { model.buttons.forEach(b => b.blur()); model.lastSelected = false;});
     });
     document.addEventListener('keydown', (event) => {
       if (event.ctrlKey) { return; }
       const key = event.key.toLowerCase(); // Normalize to lowercase
       //console.log(`pressed key ${key}`);
       let index = keyMapping(key);
       if (index == null) { return; }
       if (index == 10) {
          //model.nextButton.click();
           if(model.data.picked_id == null) { model.confirm();}
           else { moveNewPick(model); }
          return;
       }
       if(model.data.picked_id == null) {   model.showConfirmButton();}
       model.buttons.forEach(b =>(b == buttons[index]? b.focus () : b.blur()));
       model.lastSelected = buttons[index];
     });

     model.isCorrectTransaction = ((transaction) => {
       return model.data.correct_id == transaction.id;
     });
     model.isCorrect = (() => {
       return model.data.correct_id == model.data.picked_id;
     });
     model.isAnswered = (() => {
       return model.data.picked_id != null;
     });
     model.hideNextButton = () => {
        model.nextButton.classList.add('transparent');
     };
     model.onMoveNextClick = () => moveNewPick(model);
     model.showNextButton = () => {
        model.nextButton.className = 'btn-next';
        model.nextButton.optionText.innerHTML = 'Next';
        model.nextButton.onclick = model.onMoveNextClick;
        model.nextButton.isConfirm = false;
        model.buttons.forEach(b => {b.blur(); });
     };

     model.showConfirmButton = () => {
        model.nextButton.className = 'btn-next';
        model.nextButton.onclick = model.confirm;
        model.nextButton.optionText.innerHTML = 'Confirm';
        model.nextButton.isConfirm = true;
        buttons.forEach(b => {b.blur(); });
     };
    return model;
  }
  root.form_form_model_from = form_form_model_from;

  function keyMapping(key) {
    switch (key) {
      case '7':
      case 'q':
      case 'й':
      case 'home':
        return 0;
      case '8':
      case 'w':
      case 'ц':
      case 'arrowup':
        return 1;
      case '9':
      case 'e':
      case 'у':
      case 'pageup':
        return 2;
      case '4':
      case 'a':
      case 'ф':
      case 'arrowleft':
        return 3;
      case '5':
      case 's':
      case 'ы':
      case 'clear':
        return 4;
      case '6':
      case 'd':
      case 'в':
      case 'arrowright':
        return 5;
      case '1':
      case 'z':
      case 'я':
      case 'end':
        return 6;
      case '2':
      case 'x':
      case 'ч':
      case 'arrowdown':
        return 7;
      case '3':
      case 'c':
      case 'с':
      case 'pagedown':
        return 8;
      case '0':
      case '\\':
      case '|':
      case '/':
      case 'insert':
      case 'shift':
      //case 'control':
      case 'alt':
        return 9;
      case 'enter':
      case ' ':
      case 'del':
      case '.':
        return 10;
      default:
        return null;
    }
  }





  var declared;
  try {
    root.pick_model_inits = root.pick_model_inits ? root.pick_model_inits : [];
    declared = true;
  } catch(e) {
    declared = false;
  }
  root.pick_model_inits = declared ? root.pick_model_inits : [];
  root.pick_model_inits.forEach( (i) => {i();})
}).call(this);
