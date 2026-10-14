import type { RequiredAnyToken } from '@spree/storefront-api-v2-sdk';
import { ApiContext, ClearCartParams } from '../../types';
import getCurrentBearerOrCartToken from '../authentication/getCurrentBearerOrCartToken';

export default async function clearCart({ client, config }: ApiContext, { token }: ClearCartParams): Promise<void> {
  const currency = await config.internationalization.getCurrency();
  const currentToken = await getCurrentBearerOrCartToken({ client, config }) as RequiredAnyToken;

  const result = await client.cart.emptyCart({
    ...currentToken,
    currency
  });

  if (result.isFail()) {
    throw result.fail();
  }
}
