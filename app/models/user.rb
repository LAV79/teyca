# frozen_string_literal: true

# Модель User
class User < Sequel::Model
  many_to_one :template
end

# CREATE TABLE IF NOT EXISTS "users"
# (
# 	id INTEGER not null
# 		constraint user_pk
# 			primary key autoincrement,
# 	template_id INT not null
# 		constraint template_id
# 			references "templates",
# 	name varchar(255) not null
# , bonus numeric);
# CREATE UNIQUE INDEX user_id_uindex
# 	on "users" (id);
