# frozen_string_literal: true

require 'pry'

module Lobanov
  class SchemaByObject
    UNWANTED_FIELDS = %w[$schema description].freeze
    COMMENT_FOR_GENERATED_SCHEMA = ''

    def self.call(...)
      new.call(...)
    end

    def call(obj)
      require 'json-schema-generator'
      serialized_schema = JSON::SchemaGenerator.generate(
        COMMENT_FOR_GENERATED_SCHEMA,
        JSON.dump(obj),
        schema_version: 'draft4'
      )
      schema = JSON.parse(serialized_schema)
      remove_unwanted_fields(schema)
      add_examples_to_schema(schema, obj)
    end

    private

    def remove_unwanted_fields(schema)
      UNWANTED_FIELDS.each { |field| schema.delete field }
      schema
    end

    def add_examples_to_schema(schema, obj)
      if obj.is_a?(Hash)
        obj.each_key do |key|
          add_example_for_key(schema, obj, key)
        end
      elsif obj.is_a?(Array)
        add_examples_to_schema(schema['items'], obj.first)
      elsif schema['example'].nil?
        schema['example'] = obj
      end

      schema
    end

    def add_example_for_key(schema, obj, key)
      property = obj[key]
      skey = key.to_s

      case property
      when Hash
        add_examples_to_schema(schema['properties'][skey], obj[key])
      when Array
        add_example_array(obj, schema, skey, key)
      else
        add_example_simple(obj, schema, skey, key)
      end
    end

    def add_example_array(obj, schema, skey, key)
      example = obj[key].detect { |val| val.is_a?(Numeric) || !val.empty? }
      return if schema['properties'][skey]['items'].empty?

      add_examples_to_schema(schema['properties'][skey]['items'], example)
    end

    def add_example_simple(obj, schema, skey, key)
      return unless schema['properties'][skey]['example'].nil?

      example = obj[key]
      # Предупреждаем, если в тесте есть поле, но нет реального примера
      # по nil мы не можем на вывести тип
      # пустая строка тоже плохо, лучше в качестве примера дать заполненную
      if example.nil? || example == ''
        # raise MissingExampleError.new("for #{key.inspect} in #{obj}")
        # TODO: показывать в режиме VERBOSE_LOBANOV=true?
        # puts "❗️❗️❗️LOBANOV WARNING: Cannot find example for #{key.inspect} in:"
        # pp obj
      end
      # эта проверка неправильная, схема всегда генерится без примера
      # проблема просто в том, что схема перегенерируется, потому что не находится
      # и аналогичная проверка выше тоже.
      # TODO: починить загрузку и сверку схемы, покрыть тестами
      if example.nil?
        schema['properties'][skey]['nullable'] = true
      else
        schema['properties'][skey]['example'] = example
      end
    end
  end
end
