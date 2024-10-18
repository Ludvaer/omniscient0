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

rails generate scaffold TranslationSet
rails generate migration CreateJoinTableTranslationTranslationSet translation translation_set
rails generate migration RemoveSetIdFromPickWordInSet set_id:integer
rails generate migration AddTranslationSetRefToPickWordInSet translation_set:references
rails generate migration AddUserRefToPickWordInSet user:references
