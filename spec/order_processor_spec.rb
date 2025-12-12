# frozen_string_literal: true

require './src/order_processor'

RSpec.describe OrderProcessor do
  let(:lines) { [] }

  before do
    allow(File).to receive(:readlines).with('input.txt').and_return(lines)
  end

  shared_context 'with discount calculations' do
    subject(:output) { capture_stdout { described_class.new.run } }

    let(:lines_output) { output.split("\n") }
    let(:discounts) do
      lines_output.map do |line|
        discount_str = line.split.last
        discount_str == '-' ? 0 : discount_str.to_f
      end
    end
    let(:total_discount) { discounts.sum }
  end

  describe '#run' do
    subject(:processor) { described_class.new }

    context 'with a valid order' do
      let(:lines) { ["2015-02-01 M LP\n"] }
      let(:expected_output) { "2015-02-01 M LP 4.90 -\n" }

      it 'outputs the order with formatted price and no discount' do
        expect { processor.run }.to output(expected_output).to_stdout
      end
    end

    context 'with multiple valid orders' do
      let(:lines) { ["2015-02-01 M LP\n", "2015-02-02 L MR\n"] }
      let(:expected_output) { "2015-02-01 M LP 4.90 -\n2015-02-02 L MR 4.00 -\n" }

      it 'outputs all orders in sequence' do
        expect { processor.run }.to output(expected_output).to_stdout
      end
    end

    describe 'small size discount rule' do
      context 'when order is S size from MR' do
        let(:lines) { ["2015-02-01 S MR\n"] }
        let(:expected_output) { "2015-02-01 S MR 1.50 0.50\n" }

        it 'applies 0.50 discount to match lowest S price' do
          expect { processor.run }.to output(expected_output).to_stdout
        end
      end

      context 'when order is S size from LP' do
        let(:lines) { ["2015-02-01 S LP\n"] }
        let(:expected_output) { "2015-02-01 S LP 1.50 -\n" }

        it 'applies no discount as LP already has lowest S price' do
          expect { processor.run }.to output(expected_output).to_stdout
        end
      end

      context 'when processing multiple S size orders' do
        let(:lines) { ["2015-02-01 S MR\n", "2015-02-02 S MR\n", "2015-02-03 S LP\n"] }
        let(:expected_output) { "2015-02-01 S MR 1.50 0.50\n2015-02-02 S MR 1.50 0.50\n2015-02-03 S LP 1.50 -\n" }

        it 'applies discount to each MR order independently' do
          expect { processor.run }.to output(expected_output).to_stdout
        end
      end
    end

    describe 'large La Poste discount rule' do
      context 'when processing first L LP order in a month' do
        let(:lines) { ["2015-02-01 L LP\n"] }
        let(:expected_output) { "2015-02-01 L LP 6.90 -\n" }

        it 'applies no discount' do
          expect { processor.run }.to output(expected_output).to_stdout
        end
      end

      context 'when processing second L LP order in a month' do
        let(:lines) { ["2015-02-01 L LP\n", "2015-02-02 L LP\n"] }
        let(:expected_output) { "2015-02-01 L LP 6.90 -\n2015-02-02 L LP 6.90 -\n" }

        it 'applies no discount to either order' do
          expect { processor.run }.to output(expected_output).to_stdout
        end
      end

      context 'when processing third L LP order in a month' do
        let(:lines) { ["2015-02-01 L LP\n", "2015-02-02 L LP\n", "2015-02-03 L LP\n"] }
        let(:expected_output) { "2015-02-01 L LP 6.90 -\n2015-02-02 L LP 6.90 -\n2015-02-03 L LP 0.00 6.90\n" }

        it 'applies full 6.90 discount making it free' do
          expect { processor.run }.to output(expected_output).to_stdout
        end
      end

      context 'when processing fourth L LP order in same month' do
        let(:lines) do
          [
            "2015-02-01 L LP\n",
            "2015-02-02 L LP\n",
            "2015-02-03 L LP\n",
            "2015-02-04 L LP\n"
          ]
        end
        let(:expected_output) do
          "2015-02-01 L LP 6.90 -\n2015-02-02 L LP 6.90 -\n2015-02-03 L LP 0.00 6.90\n2015-02-04 L LP 6.90 -\n"
        end

        it 'does not apply discount to orders after the third' do
          expect { processor.run }.to output(expected_output).to_stdout
        end
      end

      context 'when L LP orders span different months' do
        let(:lines) do
          [
            "2015-02-01 L LP\n",
            "2015-02-02 L LP\n",
            "2015-03-01 L LP\n"
          ]
        end
        let(:expected_output) { "2015-02-01 L LP 6.90 -\n2015-02-02 L LP 6.90 -\n2015-03-01 L LP 6.90 -\n" }

        it 'resets the counter for the new month' do
          expect { processor.run }.to output(expected_output).to_stdout
        end
      end

      context 'when third L LP occurs in a new month after two in previous' do
        let(:lines) do
          [
            "2015-02-01 L LP\n",
            "2015-02-02 L LP\n",
            "2015-03-01 L LP\n",
            "2015-03-02 L LP\n",
            "2015-03-03 L LP\n"
          ]
        end
        let(:expected_output) do
          "2015-02-01 L LP 6.90 -\n2015-02-02 L LP 6.90 -\n2015-03-01 L LP 6.90 -\n2015-03-02 L LP 6.90 -\n2015-03-03 L LP 0.00 6.90\n"
        end

        it 'applies free shipping to third order of each month' do
          expect { processor.run }.to output(expected_output).to_stdout
        end
      end

      context 'when L is from MR provider' do
        let(:lines) { ["2015-02-01 L MR\n", "2015-02-02 L MR\n", "2015-02-03 L MR\n"] }
        let(:expected_output) { "2015-02-01 L MR 4.00 -\n2015-02-02 L MR 4.00 -\n2015-02-03 L MR 4.00 -\n" }

        it 'does not apply the La Poste discount rule' do
          expect { processor.run }.to output(expected_output).to_stdout
        end
      end
    end

    describe 'monthly discount limit' do
      context 'when discounts are under the 10 EUR limit' do
        let(:lines) do
          [
            "2015-02-01 S MR\n",
            "2015-02-02 S MR\n",
            "2015-02-03 S MR\n"
          ]
        end
        let(:expected_output) { "2015-02-01 S MR 1.50 0.50\n2015-02-02 S MR 1.50 0.50\n2015-02-03 S MR 1.50 0.50\n" }

        it 'applies full discounts to all orders' do
          expect { processor.run }.to output(expected_output).to_stdout
        end
      end

      context 'when monthly discount reaches exactly 10 EUR' do
        include_context 'with discount calculations'

        let(:lines) { Array.new(20) { |i| format("2015-02-%02d S MR\n", i + 1) } }

        it 'allows discounts up to the limit' do
          expect(total_discount).to eq(10.0)
        end
      end

      context 'when a single discount would exceed the remaining limit' do
        include_context 'with discount calculations'

        let(:lines) do
          orders = Array.new(19) { |i| format("2015-02-%02d S MR\n", i + 1) }
          orders << "2015-02-20 L LP\n"
          orders << "2015-02-21 L LP\n"
          orders << "2015-02-22 L LP\n"
          orders
        end

        it 'caps the discount to stay within the 10 EUR limit' do
          expect(total_discount).to eq(10.0)
        end
      end

      context 'when discount limit is reached mid-order' do
        include_context 'with discount calculations'

        let(:lines) do
          orders = Array.new(18) { |i| format("2015-02-%02d S MR\n", i + 1) }
          orders << "2015-02-19 S MR\n"
          orders << "2015-02-20 S MR\n"
          orders << "2015-02-21 S MR\n"
          orders
        end

        it 'applies full discount to orders before the limit' do
          expect(discounts[19]).to eq(0.50)
        end

        it 'applies no discount to orders after the limit' do
          expect(discounts[20]).to eq(0.0)
        end
      end

      context 'when discounts span multiple months' do
        include_context 'with discount calculations'

        let(:lines) do
          feb_orders = Array.new(20) { |i| format("2015-02-%02d S MR\n", i + 1) }
          mar_orders = Array.new(5) { |i| format("2015-03-%02d S MR\n", i + 1) }
          feb_orders + mar_orders
        end
        let(:march_discounts) { discounts.last(5).sum }

        it 'resets the limit for the new month' do
          expect(march_discounts).to eq(2.50)
        end
      end
    end

    describe 'invalid orders' do
      context 'when order has invalid date' do
        let(:lines) { ["2015-02-29 S MR\n"] }
        let(:expected_output) { "2015-02-29 S MR Ignored\n" }

        it 'outputs the line with Ignored' do
          expect { processor.run }.to output(expected_output).to_stdout
        end
      end

      context 'when order has invalid size' do
        let(:lines) { ["2015-02-01 XL MR\n"] }
        let(:expected_output) { "2015-02-01 XL MR Ignored\n" }

        it 'outputs the line with Ignored' do
          expect { processor.run }.to output(expected_output).to_stdout
        end
      end

      context 'when order has invalid provider' do
        let(:lines) { ["2015-02-01 S USPS\n"] }
        let(:expected_output) { "2015-02-01 S USPS Ignored\n" }

        it 'outputs the line with Ignored' do
          expect { processor.run }.to output(expected_output).to_stdout
        end
      end

      context 'when order line is malformed' do
        let(:lines) { ["2015-02-29 CUSPS\n"] }
        let(:expected_output) { "2015-02-29 CUSPS Ignored\n" }

        it 'outputs the line with Ignored' do
          expect { processor.run }.to output(expected_output).to_stdout
        end
      end

      context 'when mixing valid and invalid orders' do
        let(:lines) { ["2015-02-01 S MR\n", "2015-02-29 CUSPS\n", "2015-02-02 M LP\n"] }
        let(:expected_output) { "2015-02-01 S MR 1.50 0.50\n2015-02-29 CUSPS Ignored\n2015-02-02 M LP 4.90 -\n" }

        it 'processes valid orders and marks invalid ones as Ignored' do
          expect { processor.run }.to output(expected_output).to_stdout
        end
      end
    end

    describe 'combined discount scenarios' do
      context 'when S discount and L LP discount apply in same month' do
        let(:lines) do
          [
            "2015-02-01 S MR\n",
            "2015-02-02 L LP\n",
            "2015-02-03 L LP\n",
            "2015-02-04 L LP\n",
            "2015-02-05 S MR\n"
          ]
        end
        let(:expected_output) do
          "2015-02-01 S MR 1.50 0.50\n2015-02-02 L LP 6.90 -\n2015-02-03 L LP 6.90 -\n2015-02-04 L LP 0.00 6.90\n2015-02-05 S MR 1.50 0.50\n"
        end

        it 'applies both discount rules correctly' do
          expect { processor.run }.to output(expected_output).to_stdout
        end
      end

      context 'when third L LP discount would exceed monthly limit' do
        include_context 'with discount calculations'

        let(:lines) do
          orders = Array.new(7) { |i| format("2015-02-%02d S MR\n", i + 1) }
          orders << "2015-02-08 L LP\n"
          orders << "2015-02-09 L LP\n"
          orders << "2015-02-10 L LP\n"
          orders
        end

        it 'caps the L LP discount to remaining limit' do
          expect(total_discount).to eq(10.0)
        end
      end
    end
  end

  private

  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
