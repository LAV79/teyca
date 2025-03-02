# frozen_string_literal: true

class Product < Sequel::Model

  def self.find_by(ids) = where(id: ids)
end

# CREATE TABLE IF NOT EXISTS "products"
# (
# 	id INTEGER not null
# 		constraint table_name_pk
# 			primary key autoincrement,
# 	name varchar(255) not null,
# 	type varchar(255),
# 	value varchar(255)
# );
# CREATE UNIQUE INDEX table_name_id_uindex
# 	on "products" (id);
