<template>
  <div>
    <DesktopMenu v-bind="{ menu: navigationMenu, getRoute, isExternalLink }" />
    <MobileMenu v-bind="{ menu: navigationMenu, getRoute, isExternalLink }" />
  </div>
</template>

<script>
import { computed } from '@nuxtjs/composition-api';
import DesktopMenu from './HeaderNavigation/DesktopMenu.vue';
import MobileMenu from './HeaderNavigation/MobileMenu.vue';

const frescoItems = [
  { label: 'Verdura', link: '/c/categoria/verdura' },
  { label: 'Frutta', link: '/c/categoria/frutta' },
  { label: 'Erbe aromatiche', link: '/c/categoria/erbe-aromatiche' },
  { label: 'Uova', link: '/c/categoria/uova' },
  { label: 'Mandorle', link: '/c/categoria/mandorle' },
  { label: 'Noci e nocciole', link: '/c/categoria/noci-e-nocciole' }
];

const dispensaItems = [
  { label: 'Farine', link: '/c/categoria/farine' },
  { label: 'Cereali, legumi e semi', link: '/c/categoria/cereali-e-legumi' },
  { label: 'Pasta', link: '/c/categoria/pasta' },
  { label: 'Olio, olive e aceto', link: '/c/categoria/olio-e-aceto' },
  { label: 'Vino', link: '/c/categoria/vino' },
  { label: 'Prodotti essiccati', link: '/c/categoria/prodotti-essiccati' }
];

const conserveItems = [
  { label: 'Miele', link: '/c/categoria/miele' },
  { label: 'Confetture', link: '/c/categoria/confetture' },
  { label: 'Passate e sughi', link: '/c/categoria/passate-e-sughi' },
  { label: 'Patè, pesti e capperi', link: '/c/categoria/pate-e-pesti' },
  { label: 'Succhi di frutta', link: '/c/categoria/succhi-di-frutta' }
];

const promozioniItems = [
  { label: 'PROMOZIONI', link: '/c/categoria/promozioni' },
  { label: 'NOVITA\'', link: '/c/categoria/novita' }
];

const allCategoriesList = [
  ...frescoItems,
  ...dispensaItems,
  ...conserveItems,
  ...promozioniItems
];

export default {
  name: 'HeaderNavigation',
  components: {
    DesktopMenu,
    MobileMenu
  },
  setup() {
    const navigationMenu = computed(() => ({
      isDisabled: false,
      items: [
        {
          label: '☰ Tutte le Categorie',
          link: '/c/categoria',
          isMegaMenu: true,
          items: allCategoriesList,
          columns: [
            { title: 'Ortofrutta e Fresco', items: frescoItems },
            { title: 'Dispensa e Cereali', items: dispensaItems },
            { title: 'Conserve, Dolci e Novità', items: [...conserveItems, ...promozioniItems] }
          ]
        },
        {
          label: 'Fresco & Ortofrutta ▾',
          link: '/c/categoria/verdura',
          items: frescoItems
        },
        {
          label: 'Dispensa & Cereali ▾',
          link: '/c/categoria/cereali-e-legumi',
          items: dispensaItems
        },
        {
          label: 'Conserve & Dolci ▾',
          link: '/c/categoria/miele',
          items: conserveItems
        },
        {
          label: 'Offerte & Novità ▾',
          link: '/c/categoria/promozioni',
          items: promozioniItems
        }
      ]
    }));

    const getRoute = (category) => category.link || '/';
    const isExternalLink = (category) => Boolean(category.link && (category.link.startsWith('http://') || category.link.startsWith('https://')));

    return {
      navigationMenu,
      getRoute,
      isExternalLink
    };
  }
};
</script>
