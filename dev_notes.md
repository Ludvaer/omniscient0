Shulte TODO:
handle not logged in users;
hide saving form;

scaffold commands used to organize language related db:
# main languages that can be picked to learn
rails generate scaffold Language name:string
# some languages need several sublanguages like japanse needs translations between kanji and corresponding kana
rails generate scaffold Dialect name:string language_id:integer
# word and what language, more precisely dialect they are form
rails generate scaffold Word spelling:string dialect_id:integer
rails generate scaffold Translation word_id:integer translation:string translation_dialect_id:integer

rails generate scaffold WordSet
rails generate scaffold WordInSet word_set_id:integer word_id:integer
#here is way to avoid redundancy using two tables but it's somewhat annoying
#rails generate scaffold WrongPickWordInSet correct_id:integer picked_word_in_set_id:integer  version:integer
#rails generate scaffold CorrectPickWordInSetTest correct_id:integer set_id:integer  version:integer
rails generate scaffold PickWordInSet correct_id:integer picked_id:integer set_id:integer version:integer
#this will be probably a bit more intuitive if set will include correct answer but a bit less redundant and
rails generate scaffold Description text:string

#rails generate migration AddUserRefToProducts user:references
#t.integer "word_id" :word, foreign_key: true
#rails generate migration AddWordRefToTranslations user:references

rails generate migration CreateJoinTableWordWordSet word word_set
#i am creating separate translation set table cause I want to be able to reuse tonce created set in multiple tests
rails generate scaffold TranslationSet
#has and bleongs to many relateion between translation and translationset
rails generate migration CreateJoinTableTranslationTranslationSet translation translation_set
#keeeping set of words is wrong if you don not know which translations or even to what dialet was used
rails generate migration RemoveSetIdFromPickWordInSet set_id:integer
#tracking which translations was used in which set
rails generate migration AddTranslationSetRefToPickWordInSet translation_set:references
#we need to track which user completed which test
rails generate migration AddUserRefToPickWordInSet user:references
#I want to add users ref to my words translation table to track source
rails generate migration AddUserRefToTranslation user:references

in order:
 - system to select languages which you learn and which you know -
   probably as settings profile belongs to user while user has many settings profiles
   and settings profile belongs to languages that are know and are in progress of learning with different aliases
- js script that doing testing in cycles keeping preloaded queue and cahing words and TranslationSet
- additional test variants, like translation from test and kana related
- additional fields on finished and running test like how it looks in kana, and basic kanji meaning
- but first I will suffer through exporting some data from existing dictionaries and jshop and yarxi db
- figuring out staff related to set generation based on estimation of mistake probability logic and order of learning
- ensure there is no similar word in set in terms of meaning yet there are similar suffixes or form
- fix na -ajectiv duplicates issue
- add at least serbian from eng and ru learners and english from eng
- remove obsolete tables like wordsets
. . .

current priority task is selecting words to train based on estimation of answering correctly probability
but first I need to force order of utility frequency so word would be learned started from basic to advanced

first I need to create kanji table and mark them with nicknames and utility
I probably want to avoid creating separate tables and may be I will add column
 to the words table lets call it 'priority' and then add dialect kanji
 and then save kanji as words nicknames in translations and priority for words calculate from relevant kanji

Q: Should I mark translation or word with priority? Or both?
A: Well given that word can have multiple translations and some of them may be less interesting then other
I may want to start with adding priority column to translations table and decide if words themselves
need any priority (they probably do) later
generate migration AddPriorityToTranslation priority:integer
new after i parsed kanji files I may start figuring out code that calculates estimation of probability of correct answer
based on estimation of sigma function thrown up on translation ordered by priority for not yet tested Word
but for tested words it needs come from 100% for resently added words to some midpoint beetween sigmoid estimation
and actual stats for case when actual stats of correct to incorrect answers


Iwill definetly need rewrite some request to be moar efficient

I want separete table for performance that will join users and picks while tracking
it should contain usuccesfull vs successfull vs index attmts

rails generate model UserTranslationLearnProgress user_id:big_int translation_id:big_int correct:integer failed:integer last_counter:integer
rails generate migration AddRankToTranslations rank:integer


i must fix keeping stats updated when testing !!!!
I may want to add more advanced search for common hiragana suffix and confusing translation evader later
That would require separate request for each newly created pick test which would find similar for different meaning words with similar not entirely well known.

rails generate model UserDialectProgress counter:integer
rails generate migration AddUserRefToUserDialectProgress user:references
rails generate migration AddDialectRefToUserDialectProgress dialect:references

+make text on disabled button selectable (imitate disabling with color style adn detaching onclick instead?)



!Move ClassModel from preload to pseudomodel class

!cleanup migration and db stucture before shipping

I need to decide weather I want to rebuild the interface and/to populate it from js or build a pure json reques flow for current one

!!!do not let old pick_word_in_set objects hang in memory too much
!!!check how action retrived for each ajax in new test
!I will probably add some faster navigation support through state pop and state objects

1) complete delayless test flow by keeping queue of tests,
2) rework interface and display hiragana
3) add multiple test support
4) rework queue generation to reduce regeneration of sets and learn more in order

I might also want to add some message queue to allow traking of saving progress and other stuff
!do something about links below interactive fields (remain old)
!need to clenaup non id calls from _form render to ensure pure js render
!need to redisign index with single load data call

!shuffle and safe order of words (like you do with numbers in shilte)
!track actual answers to predicted and make correction intu target

test queue / probability calculation idea:
!!!Very important avoid creating duplicates when adding more words to non completed test
!!!also make priority for previously encountered words not to fall below 85% (or bellow some thershold sigmoid?)
  ???may be make higher threshold for expressions that are leftier on sigmoid
!!!make smth about totally repeating translations
(!I can probably make surelish that bad answered questions would not be skipped cause of falling on sigmoid
  by making convergence to sigmoid be estimated from correct to failed ratio)
!ensure stats incremented only when saved is true
!think about weight may be in some circumstances like after big pause correct answer should weight more ?
  !store correct and fail as floats (capped to same sum to avoid 0 increment) or bigger integer or cap normal integer
  !and allow bigger or smaller increments for various circumstances

(! add chenging taraget prob functionality)

funny  fucntionality / messages concepts:
!!1 ^_^ automaticaly increase preload queue size if user epirience delay and nervousl lcicking/miving mouse around
!!1 ^_^ tag system for tests that among ather thing allow to block pronouns related  tests

?refactor ajaxes (denodify)

!init form with more data before continue to have a proper uninterrupted flow
!need moar various checks for user access and tests for this or everythingg is messed up
!9 + 8 tests where 9 translations displayed and new word is shown each time you choosing on ranslation selected and correct one are replaced with new from pool
!!!need supprot for multiple kana
!!!need reload data if issued with saving reveal that desync happened
