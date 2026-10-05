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
          label: 'Frutta',
          link: '/c/categoria/frutta'
        },
        {
          label: 'Verdura',
          link: '/c/categoria/verdura'
        },
        {
          label: 'Farine & Cereali',
          link: '/c/categoria/farine'
        },
        {
          label: 'Miele & Confetture',
          link: '/c/categoria/miele'
        },
        {
          label: 'Tutti i Prodotti',
          link: '/c/categoria'
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
