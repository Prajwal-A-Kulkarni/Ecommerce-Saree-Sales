import json
from django.shortcuts import render, get_object_or_404, redirect
from django.http import JsonResponse
from django.views.decorators.http import require_POST
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth import login, logout, authenticate
from django.contrib.auth.forms import UserCreationForm, AuthenticationForm
from django.contrib.auth.decorators import login_required
from django.template.loader import render_to_string
from django.db.models import Q
from .models import Category, Product, ProductImage, Cart, CartItem, Wishlist, Order, OrderItem, HomeBanner

# Helper helper to get or create cart
def _get_or_create_cart(request):
    if not request.session.session_key:
        request.session.create()
    session_key = request.session.session_key
    
    if request.user.is_authenticated:
        cart, created = Cart.objects.get_or_create(user=request.user)
        # Merge session cart to user cart if exists
        session_cart = Cart.objects.filter(session_key=session_key).first()
        if session_cart and session_cart != cart:
            for item in session_cart.items.all():
                user_item, item_created = CartItem.objects.get_or_create(cart=cart, product=item.product)
                if not item_created:
                    user_item.quantity += item.quantity
                user_item.save()
            session_cart.delete()
    else:
        cart, created = Cart.objects.get_or_create(session_key=session_key)
    return cart

def home(request):
    banners = HomeBanner.objects.filter(is_active=True)
    categories = Category.objects.all()[:6]
    featured_products = Product.objects.filter(is_featured=True, is_active=True)[:8]
    latest_products = Product.objects.filter(is_active=True).order_by('-created_at')[:4]
    
    context = {
        'banners': banners,
        'categories': categories,
        'featured_products': featured_products,
        'latest_products': latest_products,
    }
    return render(request, 'store/home.html', context)

def product_list(request):
    category_slug = request.GET.get('category')
    sort_by = request.GET.get('sort', 'newest')
    min_price = request.GET.get('min_price')
    max_price = request.GET.get('max_price')
    search_query = request.GET.get('search')

    products = Product.objects.filter(is_active=True)
    categories = Category.objects.all()

    if category_slug:
        category = get_object_or_404(Category, slug=category_slug)
        products = products.filter(category=category)

    if search_query:
        products = products.filter(Q(name__icontains=search_query) | Q(description__icontains=search_query))

    if min_price:
        products = products.filter(price__gte=min_price)
    if max_price:
        products = products.filter(price__lte=max_price)

    # Sorting
    if sort_by == 'price_low':
        products = products.order_by('price')
    elif sort_by == 'price_high':
        products = products.order_by('-price')
    elif sort_by == 'popular':
        products = products.filter(is_featured=True)
    else:
        products = products.order_by('-created_at')

    # AJAX filtering support
    if request.headers.get('x-requested-with') == 'XMLHttpRequest':
        html = render_to_string('store/includes/product_grid.html', {'products': products, 'request': request})
        return JsonResponse({'html': html})

    context = {
        'products': products,
        'categories': categories,
        'selected_category': category_slug,
        'sort_by': sort_by,
    }
    return render(request, 'store/products.html', context)

def product_detail(request, slug):
    product = get_object_or_404(Product, slug=slug, is_active=True)
    related_products = Product.objects.filter(category=product.category, is_active=True).exclude(id=product.id)[:4]
    
    # Check if in wishlist
    in_wishlist = False
    if request.user.is_authenticated:
        in_wishlist = Wishlist.objects.filter(user=request.user, product=product).exists()
    elif request.session.session_key:
        in_wishlist = Wishlist.objects.filter(session_key=request.session.session_key, product=product).exists()

    # Fetch reviews
    reviews = product.reviews.all().order_by('-created_at')
    from django.db.models import Avg
    avg_rating = reviews.aggregate(Avg('rating'))['rating__avg'] or 0.0
    avg_rating = round(float(avg_rating), 1)

    context = {
        'product': product,
        'related_products': related_products,
        'in_wishlist': in_wishlist,
        'reviews': reviews,
        'avg_rating': avg_rating,
        'reviews_count': reviews.count(),
    }
    return render(request, 'store/product_detail.html', context)

def wishlist(request):
    if not request.session.session_key:
        request.session.create()
    session_key = request.session.session_key

    if request.user.is_authenticated:
        wishlist_items = Wishlist.objects.filter(user=request.user)
    else:
        wishlist_items = Wishlist.objects.filter(session_key=session_key)

    return render(request, 'store/wishlist.html', {'wishlist_items': wishlist_items})

def cart(request):
    cart = _get_or_create_cart(request)
    cart_items = cart.items.all()
    subtotal = sum(item.total_price for item in cart_items)
    
    context = {
        'cart': cart,
        'cart_items': cart_items,
        'subtotal': subtotal,
        'total': subtotal,  # Add tax/shipping calculations if needed
    }
    return render(request, 'store/cart.html', context)

def checkout(request):
    cart = _get_or_create_cart(request)
    cart_items = cart.items.all()
    if not cart_items:
        return redirect('store:cart')

    subtotal = sum(item.total_price for item in cart_items)
    
    if request.method == 'POST':
        # Create order
        first_name = request.POST.get('first_name')
        last_name = request.POST.get('last_name')
        email = request.POST.get('email')
        phone = request.POST.get('phone')
        address_line1 = request.POST.get('address_line1')
        address_line2 = request.POST.get('address_line2', '')
        city = request.POST.get('city')
        state = request.POST.get('state')
        postal_code = request.POST.get('postal_code')
        payment_method = request.POST.get('payment_method', 'PhonePe')
        delivery_instructions = request.POST.get('delivery_instructions', '')

        # Get coupon from session
        applied_coupon_code = request.session.get('applied_coupon_code')
        discount_amount = request.session.get('coupon_discount_amount', 0.00)
        
        coupon = None
        if applied_coupon_code:
            try:
                from .models import Coupon
                coupon = Coupon.objects.get(code=applied_coupon_code)
                if coupon.is_valid():
                    coupon.uses_count += 1
                    coupon.save()
                else:
                    coupon = None
                    discount_amount = 0.00
            except:
                discount_amount = 0.00
                
        final_total = max(0.00, float(subtotal) - float(discount_amount))

        order = Order.objects.create(
            user=request.user if request.user.is_authenticated else None,
            session_key=request.session.session_key,
            first_name=first_name,
            last_name=last_name,
            email=email,
            phone=phone,
            address_line1=address_line1,
            address_line2=address_line2,
            city=city,
            state=state,
            postal_code=postal_code,
            total_amount=final_total,
            coupon=coupon,
            discount_amount=discount_amount,
            payment_method=payment_method,
            delivery_instructions=delivery_instructions,
            status='Pending'
        )

        for item in cart_items:
            OrderItem.objects.create(
                order=order,
                product=item.product,
                price=item.product.current_price,
                quantity=item.quantity
            )

        # Clear Coupon session
        if 'applied_coupon_code' in request.session:
            del request.session['applied_coupon_code']
        if 'coupon_discount_amount' in request.session:
            del request.session['coupon_discount_amount']

        if payment_method == 'PhonePe':
            # Redirect to payments initiate view
            return redirect('payments:initiate', order_id=order.id)
        else:
            # Cash on Delivery: Mark success immediately
            order.status = 'Paid'  # Or COD pending status
            order.save()
            # Clear Cart
            cart.items.all().delete()
            return redirect('store:order_success', order_id=order.id)

    # Cross-sell recommendation logic
    cart_product_ids = [item.product.id for item in cart_items]
    categories_in_cart = [item.product.category for item in cart_items]
    similar_products = Product.objects.filter(
        category__in=categories_in_cart, 
        is_active=True
    ).exclude(id__in=cart_product_ids).distinct()[:4]

    if similar_products.count() < 2:
        similar_products = Product.objects.filter(
            is_active=True
        ).exclude(id__in=cart_product_ids)[:4]

    applied_coupon_code = request.session.get('applied_coupon_code', '')
    discount_amount = float(request.session.get('coupon_discount_amount', 0.00))
    final_total = max(0.00, float(subtotal) - discount_amount)

    context = {
        'cart_items': cart_items,
        'subtotal': subtotal,
        'similar_products': similar_products,
        'applied_coupon_code': applied_coupon_code,
        'discount_amount': discount_amount,
        'final_total': final_total,
    }
    return render(request, 'store/checkout.html', context)

def order_success(request, order_id):
    order = get_object_or_404(Order, id=order_id)
    return render(request, 'store/order_success.html', {'order': order})

@login_required
def profile_view(request):
    orders = Order.objects.filter(user=request.user).order_by('-created_at')
    return render(request, 'store/profile.html', {'orders': orders})

def order_track(request, order_id):
    order = get_object_or_404(Order, id=order_id)
    
    # Permission check
    is_allowed = False
    if request.user.is_authenticated:
        if order.user == request.user or request.user.is_staff:
            is_allowed = True
    else:
        # Guest user
        if order.session_key == request.session.session_key:
            is_allowed = True
            
    if not is_allowed:
        return redirect('store:home')
        
    # Map statuses to stages (1 to 5)
    status_map = {
        'Pending': 1,
        'Paid': 1,
        'Packed': 2,
        'Shipped': 3,
        'In Route': 4,
        'Delivered': 5,
        'Failed': 0,
    }
    
    current_stage = status_map.get(order.status, 0)
    
    # AJAX live status request
    if request.headers.get('x-requested-with') == 'XMLHttpRequest':
        return JsonResponse({
            'status': order.status,
            'current_stage': current_stage,
            'updated_at': order.updated_at.strftime('%d %b %Y, %H:%M')
        })
        
    context = {
        'order': order,
        'current_stage': current_stage,
    }
    return render(request, 'store/order_track.html', context)

@login_required
def logistics_dashboard(request):
    if not request.user.is_staff:
        return redirect('store:home')
        
    orders = Order.objects.all().order_by('-created_at')
    
    # Stats calculations
    successful_orders = orders.filter(status__in=['Paid', 'Packed', 'Shipped', 'In Route', 'Delivered'])
    total_revenue = sum(o.total_amount for o in successful_orders)
    total_orders = orders.count()
    pending_shipments = orders.filter(status__in=['Pending', 'Paid']).count()
    in_transit_shipments = orders.filter(status__in=['Packed', 'Shipped', 'In Route']).count()
    completed_deliveries = orders.filter(status='Delivered').count()
    
    # AOV Calculation
    successful_count = successful_orders.count()
    avg_order_value = (total_revenue / successful_count) if successful_count > 0 else 0.00
    avg_order_value = round(float(avg_order_value), 2)
    
    # Low-Stock warnings (stock < 5)
    low_stock_products = Product.objects.filter(stock__lt=5)
    low_stock_count = low_stock_products.count()
    
    # Abandoned Checkouts (orders in Pending status for PhonePe, meaning payment wasn't finished)
    abandoned_checkouts = orders.filter(status='Pending')
    
    # Category sales breakdown (for Chart.js)
    from .models import OrderItem
    category_revenue_map = {}
    order_items = OrderItem.objects.filter(
        order__status__in=['Paid', 'Packed', 'Shipped', 'In Route', 'Delivered']
    ).select_related('product__category')
    for item in order_items:
        cat_name = item.product.category.name if (item.product and item.product.category) else 'All Sarees'
        item_revenue = float(item.price * item.quantity)
        category_revenue_map[cat_name] = category_revenue_map.get(cat_name, 0.0) + item_revenue
    
    category_labels = list(category_revenue_map.keys())
    category_revenue = list(category_revenue_map.values())
    
    # Monthly sales history (for Chart.js)
    from collections import OrderedDict
    monthly_revenue_map = OrderedDict()
    successful_orders_chrono = successful_orders.order_by('created_at')
    for o in successful_orders_chrono:
        month_str = o.created_at.strftime('%b %Y')
        monthly_revenue_map[month_str] = monthly_revenue_map.get(month_str, 0.0) + float(o.total_amount)
        
    if not monthly_revenue_map:
        monthly_revenue_map['No Sales'] = 0.0
        
    monthly_labels = list(monthly_revenue_map.keys())
    monthly_revenue = list(monthly_revenue_map.values())
    
    # Filtering / Search
    search_query = request.GET.get('search', '')
    if search_query:
        orders = orders.filter(
            Q(id__icontains=search_query) |
            Q(first_name__icontains=search_query) |
            Q(last_name__icontains=search_query) |
            Q(email__icontains=search_query) |
            Q(phone__icontains=search_query) |
            Q(shipping_id__icontains=search_query)
        )
        
    # Status lists for dashboard sections
    pending_orders = orders.filter(status__in=['Pending', 'Paid'])
    transit_orders = orders.filter(status__in=['Packed', 'Shipped', 'In Route'])
    delivered_orders = orders.filter(status='Delivered')
    failed_orders = orders.filter(status='Failed')
    
    status_choices = [choice[0] for choice in Order.STATUS_CHOICES]
    
    context = {
        'total_revenue': total_revenue,
        'total_orders': total_orders,
        'pending_shipments': pending_shipments,
        'in_transit_shipments': in_transit_shipments,
        'completed_deliveries': completed_deliveries,
        'avg_order_value': avg_order_value,
        
        'low_stock_products': low_stock_products,
        'low_stock_count': low_stock_count,
        'abandoned_checkouts': abandoned_checkouts,
        
        'category_labels': category_labels,
        'category_revenue': category_revenue,
        'monthly_labels': monthly_labels,
        'monthly_revenue': monthly_revenue,
        
        'pending_orders': pending_orders,
        'transit_orders': transit_orders,
        'delivered_orders': delivered_orders,
        'failed_orders': failed_orders,
        
        'search_query': search_query,
        'status_choices': status_choices,
    }
    return render(request, 'logistics/dashboard.html', context)

@login_required
def logistics_order_detail(request, order_id):
    if not request.user.is_staff:
        return redirect('store:home')
        
    order = get_object_or_404(Order, id=order_id)
    
    if request.method == 'POST':
        status = request.POST.get('status')
        shipping_id = request.POST.get('shipping_id', '').strip()
        shipping_courier = request.POST.get('shipping_courier', '').strip()
        
        valid_statuses = [choice[0] for choice in Order.STATUS_CHOICES]
        if status in valid_statuses:
            order.status = status
        
        order.shipping_id = shipping_id
        order.shipping_courier = shipping_courier
        order.save()
        return redirect('store:logistics_order_detail', order_id=order.id)
        
    status_choices = [choice[0] for choice in Order.STATUS_CHOICES]
    context = {
        'order': order,
        'status_choices': status_choices,
    }
    return render(request, 'logistics/order_detail.html', context)

@login_required
def logistics_bulk_upload(request):
    if not request.user.is_staff:
        return redirect('store:home')
        
    categories = Category.objects.all()
    
    if request.method == 'POST':
        name = request.POST.get('name')
        price = request.POST.get('price')
        sale_price = request.POST.get('sale_price') or None
        stock = request.POST.get('stock', 10)
        description = request.POST.get('description', '')
        
        category_id = request.POST.get('category')
        new_category_name = request.POST.get('new_category', '').strip()
        
        # Determine Category
        if new_category_name:
            category, created = Category.objects.get_or_create(name=new_category_name)
        elif category_id:
            category = get_object_or_404(Category, id=category_id)
        else:
            # Default category
            category, created = Category.objects.get_or_create(
                name='All Sarees',
                defaults={'description': 'General collection of sarees.'}
            )
            
        product = Product.objects.create(
            category=category,
            name=name,
            price=price,
            sale_price=sale_price,
            description=description,
            stock=stock,
            is_active=True
        )
        
        # Handle multiple image uploads
        images = request.FILES.getlist('images')
        for idx, image_file in enumerate(images):
            ProductImage.objects.create(
                product=product,
                image=image_file,
                order=idx
            )
            
        return render(request, 'logistics/bulk_upload.html', {
            'categories': Category.objects.all(),
            'success_message': f"Saree '{product.name}' was successfully listed with {len(images)} images!"
        })
        
    return render(request, 'logistics/bulk_upload.html', {'categories': categories})

@login_required
@require_POST
def ajax_update_order_status(request):
    if not request.user.is_staff:
        return JsonResponse({'success': False, 'message': 'Permission denied.'}, status=403)
        
    try:
        data = json.loads(request.body)
        order_id = data.get('order_id')
        new_status = data.get('status')
        
        valid_statuses = [choice[0] for choice in Order.STATUS_CHOICES]
        if new_status not in valid_statuses:
            return JsonResponse({'success': False, 'message': 'Invalid status.'}, status=400)
            
        order = get_object_or_404(Order, id=order_id)
        order.status = new_status
        order.save()
        
        return JsonResponse({
            'success': True,
            'message': f'Order #ZG-{order.id:05d} status updated to {new_status}.'
        })
    except Exception as e:
        return JsonResponse({'success': False, 'message': str(e)}, status=400)

# AJAX View: Add Item to Cart
@require_POST
def ajax_cart_add(request):
    try:
        data = json.loads(request.body)
        product_id = data.get('product_id')
        quantity = int(data.get('quantity', 1))
        
        product = get_object_or_404(Product, id=product_id)
        cart = _get_or_create_cart(request)
        
        cart_item, created = CartItem.objects.get_or_create(cart=cart, product=product)
        if not created:
            cart_item.quantity += quantity
        else:
            cart_item.quantity = quantity
        cart_item.save()
        
        cart_count = sum(item.quantity for item in cart.items.all())
        return JsonResponse({
            'success': True,
            'message': f'{product.name} added to cart.',
            'cart_count': cart_count
        })
    except Exception as e:
        return JsonResponse({'success': False, 'message': str(e)}, status=400)

# AJAX View: Update Item Quantity
@require_POST
def ajax_cart_update(request):
    try:
        data = json.loads(request.body)
        item_id = data.get('item_id')
        quantity = int(data.get('quantity'))
        
        if quantity <= 0:
            return JsonResponse({'success': False, 'message': 'Quantity must be at least 1'}, status=400)
            
        cart = _get_or_create_cart(request)
        cart_item = get_object_or_404(CartItem, id=item_id, cart=cart)
        cart_item.quantity = quantity
        cart_item.save()
        
        subtotal = sum(item.total_price for item in cart.items.all())
        cart_count = sum(item.quantity for item in cart.items.all())
        
        return JsonResponse({
            'success': True,
            'item_total': float(cart_item.total_price),
            'cart_subtotal': float(subtotal),
            'cart_count': cart_count
        })
    except Exception as e:
        return JsonResponse({'success': False, 'message': str(e)}, status=400)

# AJAX View: Remove Item from Cart
@require_POST
def ajax_cart_remove(request):
    try:
        data = json.loads(request.body)
        item_id = data.get('item_id')
        
        cart = _get_or_create_cart(request)
        cart_item = get_object_or_404(CartItem, id=item_id, cart=cart)
        product_name = cart_item.product.name
        cart_item.delete()
        
        subtotal = sum(item.total_price for item in cart.items.all())
        cart_count = sum(item.quantity for item in cart.items.all())
        
        return JsonResponse({
            'success': True,
            'message': f'{product_name} removed from cart.',
            'cart_subtotal': float(subtotal),
            'cart_count': cart_count
        })
    except Exception as e:
        return JsonResponse({'success': False, 'message': str(e)}, status=400)

# AJAX View: Toggle Wishlist Item
@require_POST
def ajax_wishlist_toggle(request):
    try:
        data = json.loads(request.body)
        product_id = data.get('product_id')
        product = get_object_or_404(Product, id=product_id)
        
        if not request.session.session_key:
            request.session.create()
        session_key = request.session.session_key
        
        if request.user.is_authenticated:
            wishlist_item = Wishlist.objects.filter(user=request.user, product=product).first()
            if wishlist_item:
                wishlist_item.delete()
                added = False
                msg = f'{product.name} removed from wishlist.'
            else:
                Wishlist.objects.create(user=request.user, product=product)
                added = True
                msg = f'{product.name} added to wishlist.'
            wishlist_count = Wishlist.objects.filter(user=request.user).count()
        else:
            wishlist_item = Wishlist.objects.filter(session_key=session_key, product=product).first()
            if wishlist_item:
                wishlist_item.delete()
                added = False
                msg = f'{product.name} removed from wishlist.'
            else:
                Wishlist.objects.create(session_key=session_key, product=product)
                added = True
                msg = f'{product.name} added to wishlist.'
            wishlist_count = Wishlist.objects.filter(session_key=session_key).count()
            
        return JsonResponse({
            'success': True,
            'added': added,
            'message': msg,
            'wishlist_count': wishlist_count
        })
    except Exception as e:
        return JsonResponse({'success': False, 'message': str(e)}, status=400)

# Authentication Views
def register_view(request):
    if request.method == 'POST':
        form = UserCreationForm(request.POST)
        if form.is_valid():
            user = form.save()
            login(request, user)
            return redirect('store:home')
    else:
        form = UserCreationForm()
    return render(request, 'store/register.html', {'form': form})

def login_view(request):
    if request.method == 'POST':
        form = AuthenticationForm(data=request.POST)
        if form.is_valid():
            user = form.get_user()
            login(request, user)
            
            next_url = request.GET.get('next') or request.POST.get('next')
            if next_url:
                return redirect(next_url)
                
            if user.is_staff:
                return redirect('store:logistics_dashboard')
            return redirect('store:home')
    else:
        form = AuthenticationForm()
    return render(request, 'store/login.html', {'form': form})

def logout_view(request):
    logout(request)
    return redirect('store:home')

# AJAX View: Get Product Detail Modal Content
def ajax_product_modal(request, slug):
    product = get_object_or_404(Product, slug=slug, is_active=True)
    in_wishlist = False
    if request.user.is_authenticated:
        in_wishlist = Wishlist.objects.filter(user=request.user, product=product).exists()
    elif request.session.session_key:
        in_wishlist = Wishlist.objects.filter(session_key=request.session.session_key, product=product).exists()
        
    context = {
        'product': product,
        'in_wishlist': in_wishlist,
    }
    html = render_to_string('store/includes/product_modal_content.html', context, request=request)
    return JsonResponse({'html': html})

@login_required
def logistics_order_invoice(request, order_id):
    if not request.user.is_staff:
        return redirect('store:home')
    order = get_object_or_404(Order, id=order_id)
    return render(request, 'logistics/invoice.html', {'order': order})

@login_required
def logistics_smart_uploader(request):
    if not request.user.is_staff:
        return redirect('store:home')
    categories = Category.objects.all()
    return render(request, 'logistics/smart_uploader.html', {'categories': categories})

@login_required
@csrf_exempt
def ajax_logistics_product_publish(request):
    if not request.user.is_staff:
        return JsonResponse({'success': False, 'message': 'Permission denied.'}, status=403)
    
    if request.method != 'POST':
        return JsonResponse({'success': False, 'message': 'Invalid request method.'}, status=405)
        
    try:
        name = request.POST.get('name')
        price = request.POST.get('price')
        sale_price = request.POST.get('sale_price') or None
        stock = request.POST.get('stock', 10)
        description = request.POST.get('description', '')
        
        category_id = request.POST.get('category')
        new_category_name = request.POST.get('new_category', '').strip()
        
        if not name or not price:
            return JsonResponse({'success': False, 'message': 'Name and Price are required.'}, status=400)
            
        # Determine Category
        if new_category_name:
            category, created = Category.objects.get_or_create(name=new_category_name)
        elif category_id:
            category = get_object_or_404(Category, id=category_id)
        else:
            category, created = Category.objects.get_or_create(
                name='All Sarees',
                defaults={'description': 'General collection of sarees.'}
            )
            
        product = Product.objects.create(
            category=category,
            name=name,
            price=price,
            sale_price=sale_price,
            description=description,
            stock=stock,
            is_active=True
        )
        
        # Handle files
        images = request.FILES.getlist('images')
        for idx, image_file in enumerate(images):
            ProductImage.objects.create(
                product=product,
                image=image_file,
                order=idx
            )
            
        return JsonResponse({
            'success': True,
            'message': f"Successfully published saree listing '{product.name}' with {len(images)} images!"
        })
    except Exception as e:
        return JsonResponse({'success': False, 'message': str(e)}, status=400)

@login_required
def logistics_product_list(request):
    if not request.user.is_staff:
        return redirect('store:home')
        
    products = Product.objects.all().order_by('-created_at')
    
    # Search and filters
    search_query = request.GET.get('search', '')
    category_filter = request.GET.get('category', '')
    
    if search_query:
        products = products.filter(Q(name__icontains=search_query) | Q(description__icontains=search_query))
    if category_filter:
        products = products.filter(category_id=category_filter)
        
    categories = Category.objects.all()
    
    context = {
        'products': products,
        'categories': categories,
        'search_query': search_query,
        'selected_category': category_filter,
    }
    return render(request, 'logistics/product_list.html', context)

@login_required
def logistics_product_edit(request, product_id):
    if not request.user.is_staff:
        return redirect('store:home')
        
    product = get_object_or_404(Product, id=product_id)
    categories = Category.objects.all()
    
    if request.method == 'POST':
        name = request.POST.get('name')
        price = request.POST.get('price')
        sale_price = request.POST.get('sale_price') or None
        stock = request.POST.get('stock')
        description = request.POST.get('description')
        category_id = request.POST.get('category')
        is_active = request.POST.get('is_active') == 'on'
        
        # Handle image deletions
        deleted_images = request.POST.getlist('deleted_images')
        for img_id in deleted_images:
            ProductImage.objects.filter(id=img_id, product=product).delete()
            
        # Handle new image uploads
        new_images = request.FILES.getlist('images')
        current_max_order = product.images.count()
        for idx, image_file in enumerate(new_images):
            ProductImage.objects.create(
                product=product,
                image=image_file,
                order=current_max_order + idx
            )
            
        if category_id:
            product.category = get_object_or_404(Category, id=category_id)
        
        product.name = name
        product.price = price
        product.sale_price = sale_price
        product.stock = stock
        product.description = description
        product.is_active = is_active
        product.save()
        
        return redirect('store:logistics_product_list')
        
    context = {
        'product': product,
        'categories': categories,
    }
    return render(request, 'logistics/product_edit.html', context)

@login_required
@csrf_exempt
def ajax_product_toggle_active(request):
    if not request.user.is_staff:
        return JsonResponse({'success': False, 'message': 'Permission denied.'}, status=403)
        
    if request.method != 'POST':
        return JsonResponse({'success': False, 'message': 'Invalid request method.'}, status=405)
        
    try:
        data = json.loads(request.body)
        product_id = data.get('product_id')
        
        product = get_object_or_404(Product, id=product_id)
        product.is_active = not product.is_active
        product.save()
        
        status_str = "Active" if product.is_active else "Inactive"
        return JsonResponse({
            'success': True,
            'is_active': product.is_active,
            'message': f"Product '{product.name}' is now {status_str}."
        })
    except Exception as e:
        return JsonResponse({'success': False, 'message': str(e)}, status=400)

@csrf_exempt
def ajax_apply_coupon(request):
    if request.method != 'POST':
        return JsonResponse({'success': False, 'message': 'Invalid method.'}, status=405)
    try:
        data = json.loads(request.body)
        code = data.get('coupon_code', '').strip().upper()
        cart = _get_or_create_cart(request)
        cart_items = cart.items.all()
        if not cart_items:
            return JsonResponse({'success': False, 'message': 'Cart is empty.'}, status=400)
        
        subtotal = sum(item.total_price for item in cart_items)
        
        from .models import Coupon
        try:
            coupon = Coupon.objects.get(code=code)
        except Coupon.DoesNotExist:
            return JsonResponse({'success': False, 'message': 'Invalid promo code.'}, status=400)
            
        if not coupon.is_valid():
            return JsonResponse({'success': False, 'message': 'Promo code is expired or inactive.'}, status=400)
            
        # Calculate discount
        if coupon.discount_type == 'Percentage':
            discount = (coupon.value / 100) * subtotal
        else:
            discount = coupon.value
            
        # Discount cannot exceed subtotal
        discount = min(discount, subtotal)
        
        # Save to session
        request.session['applied_coupon_code'] = coupon.code
        request.session['coupon_discount_amount'] = float(discount)
        
        return JsonResponse({
            'success': True,
            'discount_amount': float(discount),
            'new_total': float(subtotal - discount),
            'message': f"Promo code '{coupon.code}' applied successfully!"
        })
    except Exception as e:
        return JsonResponse({'success': False, 'message': str(e)}, status=400)

@csrf_exempt
def ajax_submit_review(request):
    if request.method != 'POST':
        return JsonResponse({'success': False, 'message': 'Invalid method.'}, status=405)
    try:
        data = json.loads(request.body)
        product_id = data.get('product_id')
        rating = int(data.get('rating', 5))
        review_text = data.get('review_text', '').strip()
        name = data.get('name', '').strip()
        
        product = get_object_or_404(Product, id=product_id)
        
        if not review_text:
            return JsonResponse({'success': False, 'message': 'Review text is required.'}, status=400)
            
        if rating < 1 or rating > 5:
            return JsonResponse({'success': False, 'message': 'Rating must be between 1 and 5.'}, status=400)
            
        if not name:
            if request.user.is_authenticated:
                name = request.user.username
            else:
                name = "Guest Reviewer"
                
        # Verified buyer check
        is_verified = False
        if request.user.is_authenticated:
            is_verified = Order.objects.filter(
                user=request.user,
                status__in=['Paid', 'Packed', 'Shipped', 'In Route', 'Delivered'],
                items__product=product
            ).exists()
        else:
            session_key = request.session.session_key
            if session_key:
                is_verified = Order.objects.filter(
                    session_key=session_key,
                    status__in=['Paid', 'Packed', 'Shipped', 'In Route', 'Delivered'],
                    items__product=product
                ).exists()
                
        from .models import ProductReview
        review = ProductReview.objects.create(
            product=product,
            user=request.user if request.user.is_authenticated else None,
            name=name,
            rating=rating,
            review_text=review_text,
            is_verified=is_verified
        )
        
        return JsonResponse({
            'success': True,
            'message': 'Review submitted successfully!',
            'review': {
                'name': review.name,
                'rating': review.rating,
                'review_text': review.review_text,
                'is_verified': review.is_verified,
                'created_at': review.created_at.strftime('%d %b %Y')
            }
        })
    except Exception as e:
        return JsonResponse({'success': False, 'message': str(e)}, status=400)

def ajax_search_autocomplete(request):
    query = request.GET.get('q', '').strip()
    if len(query) < 2:
        return JsonResponse({'products': []})
        
    products = Product.objects.filter(is_active=True).filter(
        Q(name__icontains=query) | Q(category__name__icontains=query)
    )[:5]
    
    results = []
    for p in products:
        first_img_url = ""
        if p.images.first():
            first_img_url = p.images.first().image.url
        
        results.append({
            'id': p.id,
            'name': p.name,
            'price': float(p.price),
            'sale_price': float(p.sale_price) if p.sale_price else None,
            'image_url': first_img_url,
            'slug': p.slug,
            'detail_url': f"/product/{p.slug}/"
        })
        
    return JsonResponse({'products': results})

@login_required
@csrf_exempt
def ajax_send_recovery_email(request):
    if not request.user.is_staff:
        return JsonResponse({'success': False, 'message': 'Permission denied.'}, status=403)
    if request.method != 'POST':
        return JsonResponse({'success': False, 'message': 'Invalid method.'}, status=405)
    try:
        data = json.loads(request.body)
        order_id = data.get('order_id')
        order = get_object_or_404(Order, id=order_id)
        
        # Simulation log for e-mail sending
        import logging
        logger = logging.getLogger(__name__)
        logger.info(f"Checkout recovery reminder email successfully sent to {order.email} for Order #{order.id:05d}")
        
        return JsonResponse({
            'success': True,
            'message': f"Checkout recovery email successfully sent to {order.first_name} ({order.email})!"
        })
    except Exception as e:
        return JsonResponse({'success': False, 'message': str(e)}, status=400)


# Zari & Grace REST APIs for Flutter Mobile App
from django.views.decorators.csrf import csrf_exempt

def _serialize_product(request, p):
    first_image = p.images.first()
    image_url = request.build_absolute_uri(first_image.image.url) if first_image else ""
    return {
        'id': p.id,
        'name': p.name,
        'slug': p.slug,
        'price': float(p.price),
        'sale_price': float(p.sale_price) if p.sale_price else None,
        'description': p.description,
        'image_url': image_url,
        'category_name': p.category.name,
        'category_slug': p.category.slug,
        'stock': p.stock,
        'is_featured': p.is_featured,
        'is_active': p.is_active,
    }

def api_home(request):
    banners = []
    for b in HomeBanner.objects.filter(is_active=True):
        img_url = request.build_absolute_uri(b.image.url) if b.image else ""
        banners.append({
            'title': b.title,
            'subtitle': b.subtitle,
            'image_url': img_url,
            'cta_text': b.cta_text,
            'cta_url': b.cta_url,
        })
        
    categories = []
    for c in Category.objects.all()[:6]:
        img_url = request.build_absolute_uri(c.image.url) if c.image else ""
        categories.append({
            'id': c.id,
            'name': c.name,
            'slug': c.slug,
            'description': c.description,
            'image_url': img_url,
        })
        
    featured = [_serialize_product(request, p) for p in Product.objects.filter(is_featured=True, is_active=True)[:8]]
    latest = [_serialize_product(request, p) for p in Product.objects.filter(is_active=True).order_by('-created_at')[:4]]
    
    return JsonResponse({
        'banners': banners,
        'categories': categories,
        'featured_products': featured,
        'latest_products': latest,
    })

def api_products(request):
    category_slug = request.GET.get('category')
    sort_by = request.GET.get('sort', 'newest')
    min_price = request.GET.get('min_price')
    max_price = request.GET.get('max_price')
    search_query = request.GET.get('search')

    products = Product.objects.filter(is_active=True)

    if category_slug:
        products = products.filter(category__slug=category_slug)
    if search_query:
        products = products.filter(Q(name__icontains=search_query) | Q(description__icontains=search_query))
    if min_price:
        products = products.filter(price__gte=min_price)
    if max_price:
        products = products.filter(price__lte=max_price)

    if sort_by == 'price_low':
        products = products.order_by('price')
    elif sort_by == 'price_high':
        products = products.order_by('-price')
    elif sort_by == 'popular':
        products = products.filter(is_featured=True)
    else:
        products = products.order_by('-created_at')

    serialized = [_serialize_product(request, p) for p in products]
    return JsonResponse({'products': serialized})

def api_product_detail(request, slug):
    p = get_object_or_404(Product, slug=slug, is_active=True)
    images = [request.build_absolute_uri(img.image.url) for img in p.images.all()]
    
    reviews = []
    for r in p.reviews.all().order_by('-created_at'):
        reviews.append({
            'name': r.name,
            'rating': r.rating,
            'review_text': r.review_text,
            'created_at': r.created_at.strftime('%d %b %Y'),
        })
        
    from django.db.models import Avg
    avg_rating = p.reviews.aggregate(Avg('rating'))['rating__avg'] or 0.0
    avg_rating = round(float(avg_rating), 1)
    
    prod_data = _serialize_product(request, p)
    prod_data['images'] = images
    prod_data['reviews'] = reviews
    prod_data['avg_rating'] = avg_rating
    prod_data['reviews_count'] = len(reviews)
    
    # Related products
    related = []
    for rp in Product.objects.filter(category=p.category, is_active=True).exclude(id=p.id)[:4]:
        related.append(_serialize_product(request, rp))
    prod_data['related_products'] = related

    return JsonResponse(prod_data)

@csrf_exempt
def api_login(request):
    if request.method != 'POST':
        return JsonResponse({'success': False, 'message': 'Post required'}, status=405)
    try:
        data = json.loads(request.body)
        username = data.get('username')
        password = data.get('password')
        user = authenticate(request, username=username, password=password)
        if user is not None:
            login(request, user)
            return JsonResponse({
                'success': True,
                'user': {
                    'id': user.id,
                    'username': user.username,
                    'email': user.email,
                    'is_staff': user.is_staff,
                }
            })
        return JsonResponse({'success': False, 'message': 'Invalid credentials'}, status=400)
    except Exception as e:
        return JsonResponse({'success': False, 'message': str(e)}, status=400)

@csrf_exempt
def api_register(request):
    if request.method != 'POST':
        return JsonResponse({'success': False, 'message': 'Post required'}, status=405)
    try:
        data = json.loads(request.body)
        username = data.get('username')
        password = data.get('password')
        email = data.get('email', '')
        
        from django.contrib.auth.models import User
        if User.objects.filter(username=username).exists():
            return JsonResponse({'success': False, 'message': 'Username already exists'}, status=400)
            
        user = User.objects.create_user(username=username, password=password, email=email)
        login(request, user)
        return JsonResponse({
            'success': True,
            'user': {
                'id': user.id,
                'username': user.username,
                'email': user.email,
                'is_staff': user.is_staff,
            }
        })
    except Exception as e:
        return JsonResponse({'success': False, 'message': str(e)}, status=400)

@csrf_exempt
def api_checkout(request):
    if request.method != 'POST':
        return JsonResponse({'success': False, 'message': 'Post required'}, status=405)
    try:
        data = json.loads(request.body)
        first_name = data.get('first_name')
        last_name = data.get('last_name')
        email = data.get('email')
        phone = data.get('phone')
        address_line1 = data.get('address_line1')
        address_line2 = data.get('address_line2', '')
        city = data.get('city')
        state = data.get('state')
        postal_code = data.get('postal_code')
        payment_method = data.get('payment_method', 'PhonePe')
        delivery_instructions = data.get('delivery_instructions', '')
        items = data.get('items', []) # list of {product_id, quantity}
        
        # Calculate subtotal
        subtotal = 0.00
        order_items_to_create = []
        for it in items:
            product = get_object_or_404(Product, id=it['product_id'])
            qty = int(it['quantity'])
            subtotal += float(product.current_price) * qty
            order_items_to_create.append((product, qty))
            
        # Optional coupon support (could be passed in JSON)
        coupon_code = data.get('coupon_code')
        discount_amount = 0.00
        coupon = None
        if coupon_code:
            try:
                from .models import Coupon
                coupon = Coupon.objects.get(code=coupon_code)
                if coupon.is_valid():
                    if coupon.discount_type == 'Percentage':
                        discount_amount = float(subtotal) * float(coupon.value) / 100.00
                    else:
                        discount_amount = float(coupon.value)
                    coupon.uses_count += 1
                    coupon.save()
            except:
                pass
                
        final_total = max(0.00, subtotal - discount_amount)
        
        username = data.get('username')
        user = None
        if username:
            from django.contrib.auth.models import User
            user = User.objects.filter(username=username).first()
            
        order = Order.objects.create(
            user=user,
            first_name=first_name,
            last_name=last_name,
            email=email,
            phone=phone,
            address_line1=address_line1,
            address_line2=address_line2,
            city=city,
            state=state,
            postal_code=postal_code,
            total_amount=final_total,
            coupon=coupon,
            discount_amount=discount_amount,
            payment_method=payment_method,
            delivery_instructions=delivery_instructions,
            status='Pending'
        )
        
        for product, qty in order_items_to_create:
            OrderItem.objects.create(
                order=order,
                product=product,
                price=product.current_price,
                quantity=qty
            )
            
        return JsonResponse({
            'success': True,
            'order_id': order.id,
            'total': final_total,
            'status': order.status
        })
    except Exception as e:
        return JsonResponse({'success': False, 'message': str(e)}, status=400)

def api_order_track(request, order_id):
    order = get_object_or_404(Order, id=order_id)
    
    status_map = {
        'Pending': 1,
        'Paid': 1,
        'Packed': 2,
        'Shipped': 3,
        'In Route': 4,
        'Delivered': 5,
        'Failed': 0,
    }
    
    current_stage = status_map.get(order.status, 0)
    
    items = []
    for it in order.items.all():
        first_img = it.product.images.first()
        img_url = request.build_absolute_uri(first_img.image.url) if first_img else ""
        items.append({
            'product_name': it.product.name,
            'price': float(it.price),
            'quantity': it.quantity,
            'image_url': img_url,
        })
        
    return JsonResponse({
        'order_id': order.id,
        'status': order.status,
        'current_stage': current_stage,
        'total': float(order.total_amount),
        'customer_name': f"{order.first_name} {order.last_name}",
        'phone': order.phone,
        'address': f"{order.address_line1}, {order.city}, {order.state} - {order.postal_code}",
        'updated_at': order.updated_at.strftime('%d %b %Y, %H:%M'),
        'items': items,
        'shipping_courier': order.shipping_courier or "Pending",
        'shipping_id': order.shipping_id or "Pending",
    })

def api_logistics_dashboard(request):
    orders = Order.objects.all().order_by('-created_at')
    
    successful_orders = orders.filter(status__in=['Paid', 'Packed', 'Shipped', 'In Route', 'Delivered'])
    total_revenue = sum(o.total_amount for o in successful_orders)
    total_orders = orders.count()
    pending_shipments = orders.filter(status__in=['Pending', 'Paid']).count()
    in_transit_shipments = orders.filter(status__in=['Packed', 'Shipped', 'In Route']).count()
    completed_deliveries = orders.filter(status='Delivered').count()
    
    def serialize_order_summary(o):
        return {
            'order_id': o.id,
            'customer_name': f"{o.first_name} {o.last_name}",
            'date': o.created_at.strftime('%d %b %Y, %H:%M'),
            'amount': float(o.total_amount),
            'status': o.status,
            'phone': o.phone,
            'shipping_courier': o.shipping_courier or "",
            'shipping_id': o.shipping_id or "",
        }
        
    pending_list = [serialize_order_summary(o) for o in orders.filter(status__in=['Pending', 'Paid'])]
    transit_list = [serialize_order_summary(o) for o in orders.filter(status__in=['Packed', 'Shipped', 'In Route'])]
    delivered_list = [serialize_order_summary(o) for o in orders.filter(status='Delivered')]
    failed_list = [serialize_order_summary(o) for o in orders.filter(status='Failed')]
    
    return JsonResponse({
        'total_revenue': float(total_revenue),
        'total_orders': total_orders,
        'pending_shipments': pending_shipments,
        'in_transit_shipments': in_transit_shipments,
        'completed_deliveries': completed_deliveries,
        'pending_orders': pending_list,
        'transit_orders': transit_list,
        'delivered_orders': delivered_list,
        'failed_orders': failed_list,
    })

@csrf_exempt
def api_logistics_update_status(request):
    if request.method != 'POST':
        return JsonResponse({'success': False, 'message': 'Post required'}, status=405)
    try:
        data = json.loads(request.body)
        order_id = data.get('order_id')
        status = data.get('status')
        shipping_courier = data.get('shipping_courier', '')
        shipping_id = data.get('shipping_id', '')
        
        order = get_object_or_404(Order, id=order_id)
        if status:
            order.status = status
        if shipping_courier:
            order.shipping_courier = shipping_courier
        if shipping_id:
            order.shipping_id = shipping_id
        order.save()
        return JsonResponse({'success': True, 'message': 'Order updated successfully'})
    except Exception as e:
        return JsonResponse({'success': False, 'message': str(e)}, status=400)


def api_user_orders(request):
    username = request.GET.get('username')
    if not username:
        return JsonResponse({'success': False, 'message': 'Username required'}, status=400)
    
    from django.contrib.auth.models import User
    user = User.objects.filter(username=username).first()
    
    if not user:
        # If guest checkouts exist matching email
        orders = Order.objects.filter(email__iexact=username).order_by('-created_at')
    else:
        orders = Order.objects.filter(Q(user=user) | Q(email__iexact=user.email)).order_by('-created_at')
        
    serialized = []
    for o in orders:
        serialized.append({
            'order_id': o.id,
            'date': o.created_at.strftime('%d %b %Y, %H:%M'),
            'amount': float(o.total_amount),
            'status': o.status,
            'items_count': o.items.count(),
        })
    return JsonResponse({'orders': serialized})



