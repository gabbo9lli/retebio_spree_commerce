<template>
  <div class="sf-header__navigation desktop-only">
    <template v-if="isMenuAvailable">
      <div
        v-for="(category, index) in menu && menu.items"
        :key="index"
        class="nav-item-wrapper"
        @mouseenter="category.items ? openMenu(index) : null"
        @mouseleave="category.items ? closeMenu() : null"
      >
        <SfHeaderNavigationItem
          class="nav-item"
          v-e2e="`app-header-url_${category.name || category.label}`"
          :label="category.name || category.label"
          :link="isExternalLink(category) ? category.link : getRoute(category)"
        />
        <!-- Mega Menu per Tutte le Categorie -->
        <div
          v-if="category.columns && activeIndex === index"
          class="mega-menu"
        >
          <div class="mega-menu__container">
            <div
              v-for="(col, cIdx) in category.columns"
              :key="cIdx"
              class="mega-menu__column"
            >
              <h4 class="mega-menu__title">{{ col.title }}</h4>
              <ul class="mega-menu__list">
                <li
                  v-for="(item, iIdx) in col.items"
                  :key="iIdx"
                  class="mega-menu__item"
                >
                  <nuxt-link
                    :to="localePath(item.link)"
                    class="mega-menu__link"
                    @click.native="closeMenu"
                  >
                    {{ item.label }}
                  </nuxt-link>
                </li>
              </ul>
            </div>
          </div>
          <div class="mega-menu__footer">
            <nuxt-link
              :to="localePath('/c/categoria')"
              class="mega-menu__all-link"
              @click.native="closeMenu"
            >
              🌿 Vedi tutti i prodotti e categorie &rarr;
            </nuxt-link>
          </div>
        </div>

        <!-- Dropdown compatto per le singole Macro Categorie -->
        <div
          v-else-if="category.items && category.items.length && activeIndex === index"
          class="dropdown-menu"
        >
          <ul class="dropdown-menu__list">
            <li
              v-for="(item, iIdx) in category.items"
              :key="iIdx"
              class="dropdown-menu__item"
            >
              <nuxt-link
                :to="localePath(item.link)"
                class="dropdown-menu__link"
                @click.native="closeMenu"
              >
                {{ item.label }}
              </nuxt-link>
            </li>
          </ul>
        </div>
      </div>
    </template>
    <template v-else>
      The menu will show up here once it's configured and enabled in middleware.config.js
    </template>
  </div>
</template>

<script>
import { ref, computed } from '@nuxtjs/composition-api';

export default {
  name: 'DesktopMenu',
  props: {
    menu: {
      type: Object
    },
    getRoute: {
      type: Function
    },
    isExternalLink: {
      type: Function
    }
  },
  setup(props) {
    const isMenuAvailable = computed(() => props.menu && !props.menu.isDisabled);
    const activeIndex = ref(null);

    const openMenu = (index) => {
      activeIndex.value = index;
    };

    const closeMenu = () => {
      activeIndex.value = null;
    };

    return {
      isMenuAvailable,
      activeIndex,
      openMenu,
      closeMenu
    };
  }
};
</script>

<style lang="scss" scoped>
.sf-header__navigation {
  display: flex;
  align-items: center;
}

.nav-item-wrapper {
  position: relative;
}

.dropdown-menu {
  position: absolute;
  top: 100%;
  left: 0;
  min-width: 220px;
  background-color: #ffffff;
  border-radius: 8px;
  box-shadow: 0 8px 22px rgba(0, 0, 0, 0.12);
  border: 1px solid #e0e0e0;
  border-top: 3px solid #2e7d32;
  padding: 0.5rem 0;
  z-index: 1000;

  &__list {
    list-style: none;
    padding: 0;
    margin: 0;
  }

  &__item {
    margin: 0;
  }

  &__link {
    color: #4f4f4f;
    font-size: 0.9rem;
    padding: 0.55rem 1.25rem;
    display: block;
    text-decoration: none;
    transition: background-color 0.15s ease, color 0.15s ease, padding-left 0.15s ease;

    &:hover {
      background-color: #f4f9f4;
      color: #2e7d32;
      padding-left: 1.5rem;
      font-weight: 600;
    }
  }
}

.mega-menu {
  position: absolute;
  top: 100%;
  left: 0;
  width: 680px;
  background-color: #ffffff;
  border-radius: 8px;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.12);
  border: 1px solid #e0e0e0;
  border-top: 3px solid #2e7d32;
  padding: 1.25rem 1.5rem;
  z-index: 1000;

  &__container {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 1.25rem;
  }

  &__title {
    color: #2e7d32;
    font-size: 0.85rem;
    font-weight: 700;
    margin: 0 0 0.6rem 0;
    padding-bottom: 0.3rem;
    border-bottom: 2px solid #e8f5e9;
    text-transform: uppercase;
    letter-spacing: 0.03em;
  }

  &__list {
    list-style: none;
    padding: 0;
    margin: 0;
  }

  &__item {
    margin-bottom: 0.4rem;
  }

  &__link {
    color: #4f4f4f;
    font-size: 0.88rem;
    text-decoration: none;
    transition: color 0.15s ease, padding-left 0.15s ease;
    display: inline-block;

    &:hover {
      color: #2e7d32;
      padding-left: 4px;
      font-weight: 600;
    }
  }

  &__footer {
    margin-top: 1rem;
    padding-top: 0.6rem;
    border-top: 1px solid #f0f0f0;
    text-align: right;
  }

  &__all-link {
    color: #2e7d32;
    font-weight: 700;
    font-size: 0.88rem;
    text-decoration: none;

    &:hover {
      text-decoration: underline;
    }
  }
}
</style>
