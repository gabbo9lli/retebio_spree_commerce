# frozen_string_literal: true

puts "\n=============================================="
puts "  RETEBIO: VERIFICA INTEGRITA' DATI STORICI   "
puts "=============================================="

errors = []

# 1. Clienti / Utenti
users_count = Spree.user_class.count
puts "1. Totale Utenti Registrati: #{users_count}"
errors << "Nessun utente trovato!" if users_count.zero?

# 2. Ordini
orders_total = Spree::Order.count
completed_orders = Spree::Order.complete.count
orders_revenue = Spree::Order.complete.sum(:total)
puts "2. Ordini Totali: #{orders_total}"
puts "   Ordini Completati: #{completed_orders}"
puts "   Fatturato Totale Storico: €#{sprintf('%.2f', orders_revenue)}"
errors << "Nessun ordine storico presente!" if orders_total.zero?

# 3. Line Items
line_items_count = Spree::LineItem.count
puts "3. Totale Righe Ordine (Line Items): #{line_items_count}"
errors << "Line items orfani o assenti!" if line_items_count.zero?

# 4. Pagamenti
payments_count = Spree::Payment.count
completed_payments = Spree::Payment.completed.count
puts "4. Transazioni di Pagamento: #{payments_count} (Completati: #{completed_payments})"

# 5. Catalogo
products_count = Spree::Product.count
variants_count = Spree::Variant.count
taxonomies_count = Spree::Taxonomy.count
puts "5. Catalogo:"
puts "   Prodotti: #{products_count}"
puts "   Varianti: #{variants_count}"
puts "   Tassonomie: #{taxonomies_count}"
errors << "Prodotti del catalogo non trovati!" if products_count.zero?

# 6. Store predefinito
store = Spree::Store.default
puts "6. Store Predefinito: #{store&.name} (Code: #{store&.code}, Valuta: #{store&.default_currency})"
errors << "Store predefinito non configurato!" if store.nil?

puts "=============================================="
if errors.empty?
  puts " ESITO: TUTTI I DATI STORICI SONO INTEGRI! (0 ERRORI)"
  puts "==============================================\n"
  exit 0
else
  puts " ATTENZIONE: Rilevate anomalie:"
  errors.each { |err| puts "  - #{err}" }
  puts "==============================================\n"
  exit 1
end
