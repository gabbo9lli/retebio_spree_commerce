require('dotenv').config({ path: `./../../.env.${process.env.NODE_ENV}` });

const defaultFeatures = {
  spree43: {
    associateGuestCart: true,
    fetchPrimaryVariant: true,
    useMenuApi: false
  },
  spree44: {
    associateGuestCart: true,
    fetchPrimaryVariant: true,
    useMenuApi: false
  },
  spree45: {
    associateGuestCart: true,
    fetchPrimaryVariant: true,
    useMenuApi: false
  },
  spree46: {
    associateGuestCart: true,
    fetchPrimaryVariant: true,
    useMenuApi: false
  }
};

module.exports = {
  integrations: {
    spree: {
      location: '@vue-storefront/spree-api/server',
      configuration: {
        backendUrl: process.env.BACKEND_URL || 'http://backend:4000',
        assetsUrl: process.env.ASSETS_URL || 'http://localhost:4000',
        spreeFeatures: {
          ...defaultFeatures[process.env.SPREE_VERSION || 'spree43'],
          useMenuApi: false,
          wishlist: 'disabled'
        }
      }
    }
  }
};
