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
- figuring out staff related to set generation logic and order of learning
. . .
