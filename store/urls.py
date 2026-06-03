from django.urls import path
from . import views

app_name = 'store'

urlpatterns = [
    path('', views.home, name='home'),
    path('products/', views.product_list, name='product_list'),
    path('product/<slug:slug>/', views.product_detail, name='product_detail'),
    path('cart/', views.cart, name='cart'),
    path('wishlist/', views.wishlist, name='wishlist'),
    path('checkout/', views.checkout, name='checkout'),
    path('order/success/<int:order_id>/', views.order_success, name='order_success'),
    
    # AJAX Endpoints
    path('ajax/cart/add/', views.ajax_cart_add, name='ajax_cart_add'),
    path('ajax/cart/update/', views.ajax_cart_update, name='ajax_cart_update'),
    path('ajax/cart/remove/', views.ajax_cart_remove, name='ajax_cart_remove'),
    path('ajax/wishlist/toggle/', views.ajax_wishlist_toggle, name='ajax_wishlist_toggle'),
    path('ajax/product/modal/<slug:slug>/', views.ajax_product_modal, name='ajax_product_modal'),

    
    # Auth Endpoints
    path('auth/register/', views.register_view, name='register'),
    path('auth/login/', views.login_view, name='login'),
    path('auth/logout/', views.logout_view, name='logout'),
    path('auth/profile/', views.profile_view, name='profile'),

    # Order Tracking & Admin Control
    path('order/<int:order_id>/track/', views.order_track, name='order_track'),
    path('logistics/dashboard/', views.logistics_dashboard, name='logistics_dashboard'),
    path('logistics/order/<int:order_id>/', views.logistics_order_detail, name='logistics_order_detail'),
    path('logistics/order/<int:order_id>/invoice/', views.logistics_order_invoice, name='logistics_order_invoice'),
    path('logistics/bulk-upload/', views.logistics_bulk_upload, name='logistics_bulk_upload'),
    path('logistics/smart-uploader/', views.logistics_smart_uploader, name='logistics_smart_uploader'),
    path('logistics/products/', views.logistics_product_list, name='logistics_product_list'),
    path('logistics/product/<int:product_id>/edit/', views.logistics_product_edit, name='logistics_product_edit'),
    path('ajax/admin/order/update-status/', views.ajax_update_order_status, name='ajax_update_order_status'),
    path('ajax/logistics/product/publish/', views.ajax_logistics_product_publish, name='ajax_logistics_product_publish'),
    path('ajax/logistics/product/toggle-active/', views.ajax_product_toggle_active, name='ajax_product_toggle_active'),
    path('ajax/coupon/apply/', views.ajax_apply_coupon, name='ajax_apply_coupon'),
    path('ajax/review/submit/', views.ajax_submit_review, name='ajax_submit_review'),
    path('ajax/search/autocomplete/', views.ajax_search_autocomplete, name='ajax_search_autocomplete'),
    path('ajax/logistics/send-recovery/', views.ajax_send_recovery_email, name='ajax_send_recovery_email'),
]
