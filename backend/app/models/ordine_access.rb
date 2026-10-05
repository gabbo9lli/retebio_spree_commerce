# frozen_string_literal: true

class OrdineAccess < ApplicationRecord
  self.table_name = 'ordiniaccess'
  self.primary_key = 'id_ordine'

  def readonly?
    true
  end
end
