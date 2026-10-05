# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Viste di Confine Access (Boundary Views)', type: :model do
  describe 'listinoaccess' do
    it 'esiste come vista nel database ed espone le colonne attese' do
      expect(ActiveRecord::Base.connection.views).to include('listinoaccess')
      columns = ActiveRecord::Base.connection.columns('listinoaccess').map(&:name)
      expect(columns).to include(
        'codice_articolo',
        'codice_access',
        'articolo',
        'descrizione_articolo',
        'prezzo',
        'produttore',
        'um',
        'classe_iva',
        'disponibile_da',
        'fino_al',
        'prezzo_acquisto',
        'prezzo_aggiornato_ts'
      )
    end

    it 'è interrogabile tramite il modello ListinoAccess in sola lettura' do
      expect(ListinoAccess.new.readonly?).to be true
      expect { ListinoAccess.count }.not_to raise_error
    end
  end

  describe 'ordiniaccess' do
    it 'esiste come vista nel database ed espone le colonne attese' do
      expect(ActiveRecord::Base.connection.views).to include('ordiniaccess')
      columns = ActiveRecord::Base.connection.columns('ordiniaccess').map(&:name)
      expect(columns).to include(
        'id_ordine',
        'number',
        'totale_ordine',
        'state',
        'cliente_utente_ord',
        'email',
        'completed_at',
        'prezzo_unitario',
        'qta_ordinata',
        'codice_articolo',
        'codice_access',
        'articolo',
        'descrizione_articolo',
        'produttore',
        'um',
        'classe_iva'
      )
    end

    it 'è interrogabile tramite il modello OrdineAccess in sola lettura' do
      expect(OrdineAccess.new.readonly?).to be true
      expect { OrdineAccess.count }.not_to raise_error
    end
  end
end
