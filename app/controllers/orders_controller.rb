class OrdersController < ApplicationController

  before_action :authenticate_user!, only: [:create]

  before_action :find_order, only: [:show, :pay_with_alipay, :pay_with_wechat, :apply_to_cancel]

  def show
    @product_lists = @order.product_lists
    @template_lists = @order.template_lists
  end

  def create
    @order = Order.new(order_params)
    @order.user = current_user
    @order.total = current_cart.total_price

    if @order.save

      current_cart.cart_items.each do |cart_item|
        product_list = ProductList.new
        product_list.order = @order
        product_list.product_name = cart_item.product.title
        product_list.product_price = cart_item.product.price
        product_list.quantity = cart_item.quantity
        product_list.save
      end

      current_cart.cart_template_items.each do |cart_template_item|
        template_list = TemplateList.new
        template_list.order = @order
        template_list.template_name = cart_template_item.template.title
        template_list.template_price = cart_template_item.template.price
        template_list.save
      end

      current_cart.clean!
      OrderMailer.notify(@order).deliver!

      redirect_to order_path(@order.token)
    else
      render 'carts/checkout'
    end
  end

  def pay_with_alipay
    @order.set_payment_with!("alipay")
    @order.make_payment!

    redirect_to order_path(@order.token), notice: "使用支付宝成功完成付款"
  end

  def pay_with_wechat
    @order.set_payment_with!("wechat")
    @order.make_payment!

    redirect_to order_path(@order.token), notice: "使用微信支付成功完成付款"
  end

  def apply_to_cancel
    OrderMailer.apply_cancel(@order).deliver!
    flash[:notice] = "已提交申请"
    redirect_to :back
  end

  private

  def order_params
    params.require(:order).permit(:billing_name, :billing_address, :shipping_name, :shipping_address)
  end

  def find_order
    @order = Order.find_by_token(params[:id])
  end

end
