# frozen_string_literal: true

class ListinoAccess < ApplicationRecord
  self.table_name = 'listinoaccess'
  self.primary_key = 'codice_articolo'

  def readonly?
    true
  end
end
