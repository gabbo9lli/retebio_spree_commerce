import type { RequiredAnyToken } from '@spree/storefront-api-v2-sdk';
import { ApiContext, ApplyCouponParams } from '../../types';
import { serializeCouponCode } from '../serializers/cart';
import getCurrentBearerOrCartToken from '../authentication/getCurrentBearerOrCartToken';

export default async function applyCoupon({ client, config }: ApiContext, { token, couponCode }: ApplyCouponParams): Promise<void> {
  const currency = await config.internationalization.getCurrency();
  const currentToken = await getCurrentBearerOrCartToken({ client, config }) as RequiredAnyToken;
  const result = await client.cart.applyCouponCode({
    ...currentToken,
    ...serializeCouponCode(couponCode),
    currency
  });

  if (result.isFail()) {
    throw result.fail();
  }
}
