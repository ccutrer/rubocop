# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Lint::AmbiguousBlockAssociation, :config do
  shared_examples 'accepts' do |code|
    it 'does not register an offense' do
      expect_no_offenses(code)
    end
  end

  it_behaves_like 'accepts', 'foo == bar { baz a }'
  it_behaves_like 'accepts', 'foo ->(a) { bar a }'
  it_behaves_like 'accepts', 'some_method(a) { |el| puts el }'
  it_behaves_like 'accepts', 'some_method(a) do;puts a;end'
  it_behaves_like 'accepts', 'some_method a do;puts "dev";end'
  it_behaves_like 'accepts', 'some_method a do |e|;puts e;end'
  it_behaves_like 'accepts', 'Foo.bar(a) { |el| puts el }'
  it_behaves_like 'accepts', 'env ENV.fetch("ENV") { "dev" }'
  it_behaves_like 'accepts', 'env(ENV.fetch("ENV") { "dev" })'
  it_behaves_like 'accepts', '{ f: "b"}.fetch(:a) do |e|;puts e;end'
  it_behaves_like 'accepts', 'Hash[some_method(a) { |el| el }]'
  it_behaves_like 'accepts', 'foo = lambda do |diagnostic|;end'
  it_behaves_like 'accepts', 'Proc.new { puts "proc" }'
  it_behaves_like 'accepts', 'expect { order.save }.to(change { orders.size })'
  it_behaves_like 'accepts', 'scope :active, -> { where(status: "active") }'
  it_behaves_like 'accepts', 'scope :active, proc { where(status: "active") }'
  it_behaves_like 'accepts', 'scope :active, Proc.new { where(status: "active") }'
  it_behaves_like('accepts', 'assert_equal posts.find { |p| p.title == "Foo" }, results.first')
  it_behaves_like('accepts', 'assert_equal(posts.find { |p| p.title == "Foo" }, results.first)')
  it_behaves_like('accepts', 'assert_equal(results.first, posts.find { |p| p.title == "Foo" })')
  it_behaves_like('accepts', 'allow(cop).to receive(:on_int) { raise RuntimeError }')
  it_behaves_like('accepts', 'allow(cop).to(receive(:on_int) { raise RuntimeError })')

  context 'without parentheses' do
    context 'without receiver' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          some_method a { |el| puts el }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Parenthesize the param `a { |el| puts el }` to make sure that the block will be associated with the `a` method call.
        RUBY
      end
    end

    context 'with receiver' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          Foo.some_method a { |el| puts el }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Parenthesize the param `a { |el| puts el }` to make sure that the block will be associated with the `a` method call.
        RUBY
      end

      context 'when using safe navigation operator' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            Foo&.some_method a { |el| puts el }
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Parenthesize the param `a { |el| puts el }` to make sure that the block will be associated with the `a` method call.
          RUBY
        end
      end
    end

    context 'rspec expect {}.to change {}' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          expect { order.expire }.to change { order.events }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Parenthesize the param `change { order.events }` to make sure that the block will be associated with the `change` method call.
        RUBY
      end
    end

    context 'as a hash key' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          Hash[some_method a { |el| el }]
               ^^^^^^^^^^^^^^^^^^^^^^^^^ Parenthesize the param `a { |el| el }` to make sure that the block will be associated with the `a` method call.
        RUBY
      end
    end

    context 'with assignment' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          foo = some_method a { |el| puts el }
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Parenthesize the param `a { |el| puts el }` to make sure that the block will be associated with the `a` method call.
        RUBY
      end
    end
  end

  context 'IgnoredMethods' do
    let(:cop_config) { { 'IgnoredMethods' => %w[change] } }

    it 'does not register an offense for an ignored method' do
      expect_no_offenses(<<~RUBY)
        expect { order.expire }.to change { order.events }
      RUBY
    end

    it 'registers an offense for other methods' do
      expect_offense(<<~RUBY)
        expect { order.expire }.to update { order.events }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Parenthesize the param `update { order.events }` to make sure that the block will be associated with the `update` method call.
      RUBY
    end
  end
end
