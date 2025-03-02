# frozen_string_literal: true

# Модель Template
class Template < Sequel::Model
  TYPE = {
    'Bronze' => 0,	# только кэшбек
    'Silver' => 1,	# скидка и кэшбек
    'Gold' => 2	# только скидка
  }.freeze
end

# CREATE TABLE IF NOT EXISTS "templates"
# (
# 	id INTEGER not null
# 		constraint template_pk
# 			primary key autoincrement,
# 	name varchar(255) not null,
# 	discount int not null,
# 	cashback int not null
# );
# CREATE UNIQUE INDEX template_id_uindex
# 	on "templates" (id);
