<template>
  <SfFooter :column="4" multiple class="footer">
    <SfFooterColumn :title="$t('components.app_footer.about_us.title')">
      <SfList>
        <SfListItem
          v-for="item in $t('components.app_footer.about_us.items')"
          :key="item"
        >
          <SfMenuItem :label="item" />
        </SfListItem>
      </SfList>
      <div class="footer__socials">
        <SfImage
          class="footer__social-image"
          v-for="item in $t('components.app_footer.social.items')"
          :key="item"
          :src="'/icons/'+item+'.svg'"
          :alt="item"
          width="28"
          height="28"
        />
      </div>
    </SfFooterColumn>

    <SfFooterColumn title="Ortofrutta e Fresco">
      <SfList>
        <SfListItem
          v-for="cat in frescoCategories"
          :key="cat.link"
        >
          <SfMenuItem
            :label="cat.label"
            :link="localePath(cat.link)"
          />
        </SfListItem>
      </SfList>
    </SfFooterColumn>

    <SfFooterColumn title="Dispensa e Specialità">
      <SfList>
        <SfListItem
          v-for="cat in dispensaCategories"
          :key="cat.link"
        >
          <SfMenuItem
            :label="cat.label"
            :link="localePath(cat.link)"
          />
        </SfListItem>
      </SfList>
    </SfFooterColumn>

    <SfFooterColumn :title="$t('components.app_footer.help.title')">
      <SfList>
        <SfListItem
          v-for="item in $t('components.app_footer.help.items')"
          :key="item"
        >
          <SfMenuItem :label="item" />
        </SfListItem>
        <SfListItem
          v-for="item in $t('components.app_footer.payment_and_delivery.items')"
          :key="item"
        >
          <SfMenuItem :label="item" />
        </SfListItem>
        <SfListItem>
          <SfMenuItem
            label="🌿 Tutti i prodotti"
            :link="localePath('/c/categoria')"
          />
        </SfListItem>
      </SfList>
    </SfFooterColumn>
  </SfFooter>
</template>

<script>
import { SfFooter, SfList, SfImage, SfMenuItem } from '@storefront-ui/vue';

const frescoCategories = [
  { label: 'Verdura', link: '/c/categoria/verdura' },
  { label: 'Frutta', link: '/c/categoria/frutta' },
  { label: 'Erbe aromatiche', link: '/c/categoria/erbe-aromatiche' },
  { label: 'Uova', link: '/c/categoria/uova' },
  { label: 'Mandorle', link: '/c/categoria/mandorle' },
  { label: 'Noci e nocciole', link: '/c/categoria/noci-e-nocciole' }
];

const dispensaCategories = [
  { label: 'Farine', link: '/c/categoria/farine' },
  { label: 'Cereali, legumi e semi', link: '/c/categoria/cereali-e-legumi' },
  { label: 'Pasta', link: '/c/categoria/pasta' },
  { label: 'Olio, olive e aceto', link: '/c/categoria/olio-e-aceto' },
  { label: 'Vino', link: '/c/categoria/vino' },
  { label: 'Miele', link: '/c/categoria/miele' },
  { label: 'Confetture', link: '/c/categoria/confetture' },
  { label: 'Passate e sughi', link: '/c/categoria/passate-e-sughi' },
  { label: 'Patè, pesti e capperi', link: '/c/categoria/pate-e-pesti' },
  { label: 'Succhi di frutta', link: '/c/categoria/succhi-di-frutta' },
  { label: 'Prodotti essiccati', link: '/c/categoria/prodotti-essiccati' },
  { label: 'PROMOZIONI', link: '/c/categoria/promozioni' },
  { label: 'NOVITA\'', link: '/c/categoria/novita' }
];

export default {
  components: {
    SfFooter,
    SfList,
    SfImage,
    SfMenuItem
  },
  setup() {
    return {
      frescoCategories,
      dispensaCategories
    };
  }
};
</script>

<style lang="scss">

.footer {
  margin-bottom: 3.75rem;
  background-color: #f7faf7 !important;
  @include for-desktop {
    margin-bottom: 0;
  }
  &__socials {
    display: flex;
    justify-content: space-between;
    margin: 0 auto var(--spacer-lg);
    padding: var(--spacer-base) var(--spacer-xl);
    @include for-desktop {
      justify-content: flex-start;
      padding: var(--spacer-xs) 0;
      margin: 0 auto;
    }
  }
  &__social-image {
    margin: 0 var(--spacer-2xs) 0 0;
  }
}
.sf-footer {
  background-color: #f7faf7 !important;
  color: #333 !important;
  border-top: 3px solid #2e7d32 !important;

  @include for-desktop {
    border-top: 3px solid #2e7d32 !important;
    padding-bottom: 0;
    margin-top: var(--spacer-2xl);
  }
  &__container {
    margin: var(--spacer-sm);
    @include for-desktop {
      max-width: 69rem;
      margin: 0 auto;
    }
  }

  .sf-footer-column {
    background-color: #f7faf7 !important;
    color: #333 !important;

    &__title {
      background-color: #f7faf7 !important;
      color: #2e7d32 !important;
      font-weight: 700;
    }

    &__chevron {
      --chevron-color: #2e7d32 !important;
    }

    & .sf-list__item {
      --menu-item-label-color: #4f4f4f !important;
      color: #4f4f4f !important;

      .sf-menu-item {
        color: #4f4f4f !important;
        &:hover {
          color: #2e7d32 !important;
        }
      }

      .sf-menu-item__label {
        color: #4f4f4f !important;
        &:hover {
          color: #2e7d32 !important;
        }
      }
    }
  }
}
</style>
