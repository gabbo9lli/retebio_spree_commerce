# frozen_string_literal: true

class CreateBoundaryViewsForAccess < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL
      CREATE OR REPLACE VIEW public.listinoaccess AS
       SELECT p10.codice_articolo,
          p10.sku AS codice_access,
          p10.articolo,
          p10.descrizione_articolo,
          p10.prezzo,
          string_agg((p10.produttore)::text, ', '::text) AS produttore,
          string_agg((p10.um)::text, ', '::text) AS um,
          p10.classe_iva,
          p10.disponibile_da,
          p10.fino_al,
          p10.prezzo_acquisto,
          p10.prezzo_aggiornato_ts
         FROM ( SELECT p.id AS codice_articolo,
                  v.sku,
                  p.name AS articolo,
                  p.description AS descrizione_articolo,
                  pr.amount AS prezzo,
                  p1.value AS produttore,
                  NULL::character varying AS um,
                  t.name AS classe_iva,
                  p.available_on AS disponibile_da,
                  p.discontinue_on AS fino_al,
                  v.cost_price AS prezzo_acquisto,
                  v.updated_at AS prezzo_aggiornato_ts
                 FROM (((((public.spree_variants v
                   JOIN public.spree_products p ON ((p.id = v.product_id)))
                   JOIN public.spree_prices pr ON ((v.id = pr.variant_id)))
                   JOIN public.spree_tax_categories t ON ((v.tax_category_id = t.id)))
                   JOIN public.spree_product_properties p1 ON ((p.id = p1.product_id)))
                   JOIN public.spree_properties p2 ON ((p1.property_id = p2.id)))
                WHERE (((p2.presentation)::text = 'Produttore'::text) AND (v.deleted_at IS NULL) AND (((p.available_on < now()) AND (p.discontinue_on IS NULL)) OR ((now() >= p.available_on) AND (now() <= p.discontinue_on))))
              UNION ALL
               SELECT p.id AS codice_articolo,
                  v.sku,
                  p.name AS articolo,
                  p.description AS descrizione_articolo,
                  pr.amount AS prezzo,
                  NULL::character varying AS produttore,
                  p1.value AS um,
                  t.name AS classe_iva,
                  p.available_on AS disponibile_da,
                  p.discontinue_on AS fino_al,
                  v.cost_price AS prezzo_acquisto,
                  v.updated_at AS prezzo_aggiornato_ts
                 FROM (((((public.spree_variants v
                   JOIN public.spree_prices pr ON ((v.id = pr.variant_id)))
                   JOIN public.spree_products p ON ((p.id = v.product_id)))
                   JOIN public.spree_tax_categories t ON ((v.tax_category_id = t.id)))
                   JOIN public.spree_product_properties p1 ON ((p.id = p1.product_id)))
                   JOIN public.spree_properties p2 ON ((p1.property_id = p2.id)))
                WHERE (((p2.presentation)::text = 'Unita di Misura'::text) AND (v.deleted_at IS NULL) AND (((p.available_on < now()) AND (p.discontinue_on IS NULL)) OR ((now() >= p.available_on) AND (now() <= p.discontinue_on))))) p10
        GROUP BY p10.codice_articolo, p10.sku, p10.articolo, p10.descrizione_articolo, p10.prezzo, p10.classe_iva, p10.disponibile_da, p10.fino_al, p10.prezzo_acquisto, p10.prezzo_aggiornato_ts;

      CREATE OR REPLACE VIEW public.ordiniaccess AS
       SELECT p10.id_ordine,
          p10.number,
          p10.total AS totale_ordine,
          p10.state,
          p10.user_id AS cliente_utente_ord,
          p10.email,
          p10.completed_at,
          p10.price AS prezzo_unitario,
          p10.quantity AS qta_ordinata,
          p10.codice_articolo,
          p10.sku AS codice_access,
          p10.articolo,
          p10.descrizione_articolo,
          string_agg((p10.produttore)::text, ', '::text) AS produttore,
          string_agg((p10.um)::text, ', '::text) AS um,
          p10.classe_iva
         FROM ( SELECT o.id AS id_ordine,
                  o.number,
                  o.total,
                  o.state,
                  o.user_id,
                  o.email,
                  o.completed_at,
                  i.price,
                  i.quantity,
                  p.id AS codice_articolo,
                  v.sku,
                  p.name AS articolo,
                  p.description AS descrizione_articolo,
                  p1.value AS produttore,
                  NULL::character varying AS um,
                  t.name AS classe_iva
                 FROM ((((((public.spree_orders o
                   JOIN public.spree_line_items i ON ((o.id = i.order_id)))
                   JOIN public.spree_variants v ON ((i.variant_id = v.id)))
                   JOIN public.spree_products p ON ((p.id = v.product_id)))
                   JOIN public.spree_tax_categories t ON ((p.tax_category_id = t.id)))
                   JOIN public.spree_product_properties p1 ON ((p.id = p1.product_id)))
                   JOIN public.spree_properties p2 ON ((p1.property_id = p2.id)))
                WHERE (((p2.presentation)::text = 'Produttore'::text) AND (v.deleted_at IS NULL))
              UNION ALL
               SELECT o.id AS id_ordine,
                  o.number,
                  o.total,
                  o.state,
                  o.user_id,
                  o.email,
                  o.completed_at,
                  i.price,
                  i.quantity,
                  p.id AS codice_articolo,
                  v.sku,
                  p.name AS articolo,
                  p.description AS descrizione_articolo,
                  NULL::character varying AS produttore,
                  p1.value AS um,
                  t.name AS classe_iva
                 FROM ((((((public.spree_orders o
                   JOIN public.spree_line_items i ON ((o.id = i.order_id)))
                   JOIN public.spree_variants v ON ((i.variant_id = v.id)))
                   JOIN public.spree_products p ON ((p.id = v.product_id)))
                   JOIN public.spree_tax_categories t ON ((p.tax_category_id = t.id)))
                   JOIN public.spree_product_properties p1 ON ((p.id = p1.product_id)))
                   JOIN public.spree_properties p2 ON ((p1.property_id = p2.id)))
                WHERE (((p2.presentation)::text = 'Unita di Misura'::text) AND (v.deleted_at IS NULL))) p10
        WHERE ((p10.state)::text = 'complete'::text)
        GROUP BY p10.id_ordine, p10.number, p10.total, p10.state, p10.user_id, p10.email, p10.completed_at, p10.price, p10.quantity, p10.codice_articolo, p10.sku, p10.articolo, p10.descrizione_articolo, p10.classe_iva;
    SQL
  end

  def down
    execute <<-SQL
      DROP VIEW IF EXISTS public.listinoaccess;
      DROP VIEW IF EXISTS public.ordiniaccess;
    SQL
  end
end
