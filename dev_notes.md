Shulte TODO:
handle not logged in users;
hide saving form;

scaffold commands used to organize language related db:
rails generate scaffold Language name:string
rails generate scaffold Dialect name:string language_id:integer
rails generate scaffold Word spelling:string dialect_id:integer
rails generate scaffold Translation word_id:integer translation:string translation_dialect_id:integer
