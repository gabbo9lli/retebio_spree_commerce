<template>
  <div id="thank-you">
    <div
      v-e2e="'thank-you-banner'"
      class="banner"
    >
      <h2 class="banner__title">{{ $t('pages.checkout.thank_you.thank_you_banner_title') }}</h2>
      <div class="banner__order-number">
        <span>{{ $t('pages.checkout.thank_you.order_no') }}</span>
        <strong>{{ orderNumber }}</strong>
      </div>
    </div>
    <section class="section">
      <div class="order">
        <SfHeading
          :title="$t('pages.checkout.thank_you.your_purchase_title')"
          class="order__heading heading sf-heading--left"
          :level="3"
        />
        <p class="order__paragraph paragraph">
          {{ $t('pages.checkout.thank_you.successful_placed_order') }}
        </p>
        <div class="order__contact">
          <SfHeading
            :level="6"
            class="heading sf-heading--left sf-heading--no-underline"
            :title="$t('pages.checkout.thank_you.questions_contacts_title')"
          ></SfHeading>
          <div class="contact">
            <p class="contact__name">{{ companyDetails.name }}</p>
            <p class="contact__street">{{ companyDetails.street }}</p>
            <p class="contact__city">{{ companyDetails.city }}</p>
            <p class="contact__email">{{ companyDetails.email }}</p>
          </div>
        </div>
        <SfButton class="order__notifications-button button-size"
          >{{ $t('pages.checkout.thank_you.allow_order_notifications') }}</SfButton
        >
      </div>
      <div class="additional-info">
        <div>
          <SfHeading
            :title="$t('pages.checkout.thank_you.your_account_title')"
            class="heading sf-heading--left"
            :level="3"
          />
          <p class="paragraph">
            {{ $t('pages.checkout.thank_you.info_after_order') }}
          </p>
        </div>
        <div>
          <SfHeading
            :title="$t('pages.checkout.thank_you.what_can_we_improve')"
            class="heading sf-heading--left"
            :level="3"
          />
          <p class="paragraph">
            {{ $t('pages.checkout.thank_you.feedback') }}
          </p>
          <SfButton
            class="feedback-button color-secondary sf-button--full-width button-size"
            >{{ $t('pages.checkout.thank_you.send_my_feedback') }}</SfButton
          >
        </div>
      </div>
    </section>
    <SfButton
      class="back-button color-primary button-size"
      @click="navigateToShop"
    >
      {{ $t('pages.checkout.thank_you.go_back_to_shop') }}
    </SfButton>
  </div>
</template>

<script>
import { SfHeading, SfButton } from '@storefront-ui/vue';
import { computed, useRoute, useRouter } from '@nuxtjs/composition-api';

export default {
  components: {
    SfHeading,
    SfButton
  },
  setup(props, context) {
    context.emit('changeStep', 4);
    const route = useRoute();
    const router = useRouter();

    const companyDetails = {
      name: 'ReteBio Consorzio',
      street: 'Strada Gazzaro 17',
      city: '42024 Castelnovo di Sotto (RE)',
      email: 'info@retebio.it'
    };

    const orderNumber = computed(() => route?.value?.query?.order || '');

    const navigateToShop = () => {
      router.push(context.root.localePath('/'));
    };

    return {
      companyDetails,
      orderNumber,
      navigateToShop
    };
  }
};
</script>
<style lang="scss" scoped>
#thank-you {
  box-sizing: border-box;
  @include for-desktop {
    max-width: 1272px;
    padding: 0 var(--spacer-sm);
    margin: 0 auto;
  }
}
.banner {
  background: linear-gradient(135deg, #e8f5e9 0%, #c8e6c9 100%) !important;
  border-radius: 8px;
  border: 1px solid #a5d6a7;
  padding: 2.5rem 2rem;
  margin: 0 0 var(--spacer-xl) 0;

  &__title {
    color: #1b5e20;
    font-size: var(--h2-font-size);
    font-weight: 700;
    margin: 0 0 0.75rem 0;
  }

  &__order-number {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    font-size: 1.15rem;
    color: #2e7d32;

    strong {
      font-size: 1.35rem;
      color: #1b5e20;
      letter-spacing: 0.05em;
    }
  }
}
.section {
  display: flex;
  flex-direction: column;
  margin: 0 auto;
  @include for-desktop {
    flex-direction: row;
    padding: 0;
    background: var(--c-light);
  }
}
.order {
  background: var(--c-light);
  padding-bottom: var(--spacer-sm);
  @include for-desktop {
    width: 100%;
    padding: var(--spacer-xl) var(--spacer-xl) var(--spacer-2xl)
      var(--spacer-2xl);
  }
  &__heading {
    --heading-title-font-weight: var(--font-weight--bold);
    @include for-desktop {
      --heading-title-color: var(--c-link);
      --heading-title-font-weight: var(--font-weight--swemibold);
    }
  }
  &__heading,
  &__paragraph,
  &__contact {
    @include for-mobile {
      margin: 0;
      padding-left: var(--spacer-sm);
      padding-right: var(--spacer-sm);
    }
  }
  &__contact {
    padding-bottom: var(--spacer-base);
    --heading-title-font-size: var(--font-size--lg);
    --heading-title-font-weight: var(--font-weight--medium);
    @include for-desktop {
      --heading-title-font-size: var(--font-size--base);
      --heading-title-font-weight: var(--font-weight--normal);
      padding: 0 var(--spacer-sm);
      border: 2px solid var(--c-white);
      border-width: 2px 0 2px 0;
    }
  }
  &__notifications-button {
    --button-width: calc(100% - var(--spacer-lg));
    margin: 0 auto;
    @include for-desktop {
      margin: var(--spacer-xl) 0 0 0;
    }
  }
}
.contact {
  color: var(--c-dark-variant);
  font: var(--font-weight--light) var(--font-size--base) / 1.6
    var(--font-family--secondary);
  @include for-desktop {
    font-weight: var(--font-weight--normal);
    font-size: var(--font-size--sm);
  }
  &__name,
  &__street,
  &__city {
    margin: 0;
  }
  &__email {
    margin: var(--spacer-sm) 0 0 0;
    @include for-desktop {
      margin-bottom: var(--spacer-sm);
    }
  }
  &__name,
  &__street,
  &__city,
  &__email {
    font-size: var(--font-size--sm);
  }
}
.additional-info {
  --heading-title-font-weight: var(--font-weight--bold);
  padding: 0 var(--spacer-sm);
  @include for-desktop {
    --heading-title-color: var(--c-link);
    --heading-title-font-weight: var(--font-weight--semibold);
    width: 100%;
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    padding: var(--spacer-xl) var(--spacer-xl) var(--spacer-2xl)
      var(--spacer-2xl);
  }
}
.feedback-button {
  margin: var(--spacer-xl) 0 var(--spacer-sm) 0;
  @include for-desktop {
    margin: var(--spacer-base) 0 0 0;
  }
}
.back-button {
  --button-width: calc(100% - var(--spacer-lg));
  margin: 0 auto var(--spacer-sm) auto;
  @include for-desktop {
    margin: var(--spacer-xl) auto;
  }
}
.button-size {
  @include for-desktop {
    --button-width: 25rem;
  }
}
</style>
