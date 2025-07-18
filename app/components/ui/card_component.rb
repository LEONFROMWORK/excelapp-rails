# frozen_string_literal: true

class Ui::CardComponent < ViewComponent::Base
  renders_one :header
  renders_one :footer
  
  def initialize(padding: true, **options)
    @padding = padding
    @options = options
  end
  
  def call
    tag.div(class: card_classes, **@options) do
      if header?
        concat tag.div(header, class: header_classes)
      end
      
      concat tag.div(content, class: body_classes)
      
      if footer?
        concat tag.div(footer, class: footer_classes)
      end
    end
  end
  
  private
  
  def card_classes
    [
      "bg-white rounded-lg shadow-sm border border-gray-200",
      @options[:class]
    ].compact.join(" ")
  end
  
  def header_classes
    [
      "border-b border-gray-200",
      @padding ? "px-6 py-4" : ""
    ].compact.join(" ")
  end
  
  def body_classes
    @padding ? "px-6 py-4" : ""
  end
  
  def footer_classes
    [
      "border-t border-gray-200 bg-gray-50",
      @padding ? "px-6 py-3" : ""
    ].compact.join(" ")
  end
end
