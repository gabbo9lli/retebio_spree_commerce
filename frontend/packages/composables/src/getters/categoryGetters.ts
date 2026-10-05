import { CategoryGetters, AgnosticBreadcrumb } from '@vue-storefront/core';
import { Category, AgnosticCategoryTree } from './../../../api-client/src/types';

export const getCategoryTree = (categories: any): AgnosticCategoryTree => {
  if (!categories || !categories.root) {
    return { label: '', slug: '', localizedSlugs: {}, items: [], isCurrent: false };
  }

  const { root, current } = categories;

  const itemToTree = (category: Category): AgnosticCategoryTree => {
    if (!category) return { label: '', slug: '', localizedSlugs: {}, items: [], isCurrent: false };
    return {
      label: category.name || '',
      slug: category.slug || '',
      localizedSlugs: category.localizedSlugs || {},
      items: (category.items || []).map(itemToTree),
      isCurrent: current ? category.id === current.id : false
    };
  };

  return itemToTree(root);
};

export const getCategoryBreadcrumbs = (category: Category): AgnosticBreadcrumb[] => {
  const breadcrumbs = [{ text: 'Home', link: '/' }];
  if (!category) return breadcrumbs;

  const buildBreadcrumbs = (cat) => {
    if (!cat) return;
    if (cat.parent) buildBreadcrumbs(cat.parent);

    breadcrumbs.push({
      text: cat.name || '',
      link: `/c/${cat.slug || ''}`
    });
  };
  buildBreadcrumbs(category);

  return breadcrumbs;
};

const categoryGetters: CategoryGetters<Category> = {
  getTree: getCategoryTree,
  getBreadcrumbs: getCategoryBreadcrumbs
};

export default categoryGetters;
