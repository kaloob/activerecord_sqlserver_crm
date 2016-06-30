require 'odata/model'

module ActiveRecordExtension

  extend ActiveSupport::Concern

  def delete
    ::OData::Model.destroy(self)
  end

  def destroy
    destroy!
  rescue
    false
  end

  def destroy!
    run_callbacks :destroy do
      ::OData::Model.destroy(self)
    end
    has_errors = errors.present?
    if has_errors
      raise_record_not_destroyed
    end
    !has_errors
  end

  def save(*)
    save!
  rescue
    false
  end

  def save!(*)
    validate!
    run_callbacks :save do
      ::OData::Model.save(self)
    end
    has_errors = errors.present?
    if has_errors
      raise_record_invalid
    else
      reload
    end
    !has_errors
  end

  def update(attributes)
    attributes.each do |k,v|
      write_attribute(k,v)
    end
    save
  end

  def update_attribute(name, value)
    write_attribute(name,value)
    save
  end

  # add your static(class) methods here
  module ClassMethods
    def belongs_to_field?(field)
      @belongs_to_fields ||= belongs_to_fields
      @belongs_to_fields.map(&:foreign_key).include?(field)
    end

    def belongs_to_field(field)
      @belongs_to_fields ||= belongs_to_fields
      @belongs_to_fields.select{|f| f.foreign_key == field}.first
    end

    def belongs_to_fields
      associations = reflect_on_all_associations
      associations.select { |a| a.macro == :belongs_to }
    end

    # If odata referes to table differently than table name when using  associations, you can use this method
    def odata_table_reference
      @odata_table_reference
    end

    def odata_table_reference=(value)
      @odata_table_reference = value
    end
  end
end

# include the extension 
ActiveRecord::Base.send(:include, ActiveRecordExtension)

# Extend belongs_to for crm_key field
module BelongsToActiveRecordExtension
  def valid_options
    super + [:crm_key]
  end
end

class ActiveRecord::Associations::Builder::BelongsTo
  include ::BelongsToActiveRecordExtension
end
