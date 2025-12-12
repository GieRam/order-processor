# frozen_string_literal: true

require './src/order_processor'

RSpec.describe OrderProcessor do
  subject(:processor) { described_class.new }

  before do
    allow(File).to receive(:readlines).with('input.txt').and_return(input_lines)
  end

  describe '#run' do
    context 'happy path with valid orders' do
      let(:input_lines) do
        [
          "2015-02-01 S MR\n",
          "2015-02-02 M LP\n",
          "2015-02-03 L MR\n"
        ]
      end
      let(:expected_output) { "2015-02-01 S MR 1.50 0.50\n2015-02-02 M LP 4.90 -\n2015-02-03 L MR 4.00 -\n" }

      it 'processes orders and outputs correctly formatted results' do
        expect { processor.run }.to output(expected_output).to_stdout
      end
    end

    context 'small size discount rule (order.size == :S)' do
      context 'when S order from MR' do
        let(:input_lines) { ["2015-02-01 S MR\n"] }
        let(:expected_output) { "2015-02-01 S MR 1.50 0.50\n" }

        it 'applies 0.50 discount (2.0 - 1.5 = 0.5)' do
          expect { processor.run }.to output(expected_output).to_stdout
        end
      end

      context 'when S order from LP' do
        let(:input_lines) { ["2015-02-01 S LP\n"] }
        let(:expected_output) { "2015-02-01 S LP 1.50 -\n" }

        it 'applies no discount (already at lowest price 1.5)' do
          expect { processor.run }.to output(expected_output).to_stdout
        end
      end

      context 'when multiple S orders from MR in same month' do
        let(:input_lines) do
          [
            "2015-02-01 S MR\n",
            "2015-02-02 S MR\n",
            "2015-02-03 S MR\n"
          ]
        end
        let(:expected_output) { "2015-02-01 S MR 1.50 0.50\n2015-02-02 S MR 1.50 0.50\n2015-02-03 S MR 1.50 0.50\n" }

        it 'accumulates discounts correctly' do
          expect { processor.run }.to output(expected_output).to_stdout
        end
      end
    end

    context 'large La Poste discount rule (PROVIDERS[:LP][:L])' do
      context 'when 1st and 2nd L LP orders in a month' do
        let(:input_lines) do
          [
            "2015-02-01 L LP\n",
            "2015-02-02 L LP\n"
          ]
        end
        let(:expected_output) { "2015-02-01 L LP 6.90 -\n2015-02-02 L LP 6.90 -\n" }

        it 'applies no discount' do
          expect { processor.run }.to output(expected_output).to_stdout
        end
      end

      context 'when 3rd L LP order in a month' do
        let(:input_lines) do
          [
            "2015-02-01 L LP\n",
            "2015-02-02 L LP\n",
            "2015-02-03 L LP\n"
          ]
        end
        let(:expected_output) { "2015-02-01 L LP 6.90 -\n2015-02-02 L LP 6.90 -\n2015-02-03 L LP 0.00 6.90\n" }

        it 'applies full 6.90 discount (free shipment)' do
          expect { processor.run }.to output(expected_output).to_stdout
        end
      end

      context 'when 4th and subsequent L LP orders in a month' do
        let(:input_lines) do
          [
            "2015-02-01 L LP\n",
            "2015-02-02 L LP\n",
            "2015-02-03 L LP\n",
            "2015-02-04 L LP\n",
            "2015-02-05 L LP\n"
          ]
        end
        let(:expected_output) do
          "2015-02-01 L LP 6.90 -\n2015-02-02 L LP 6.90 -\n2015-02-03 L LP 0.00 6.90\n2015-02-04 L LP 6.90 -\n2015-02-05 L LP 6.90 -\n"
        end

        it 'applies no discount after the 3rd order' do
          expect { processor.run }.to output(expected_output).to_stdout
        end
      end

      context 'when L LP counter resets for new month' do
        let(:input_lines) do
          [
            "2015-02-01 L LP\n",
            "2015-02-02 L LP\n",
            "2015-02-03 L LP\n",
            "2015-03-01 L LP\n",
            "2015-03-02 L LP\n",
            "2015-03-03 L LP\n"
          ]
        end
        let(:expected_output) do
          "2015-02-01 L LP 6.90 -\n2015-02-02 L LP 6.90 -\n2015-02-03 L LP 0.00 6.90\n" \
            "2015-03-01 L LP 6.90 -\n2015-03-02 L LP 6.90 -\n2015-03-03 L LP 0.00 6.90\n"
        end

        it 'applies 3rd order discount in each month' do
          expect { processor.run }.to output(expected_output).to_stdout
        end
      end
    end

    context 'monthly discount limit (10 EUR cap)' do
      context 'when discounts accumulate up to 10 EUR' do
        let(:input_lines) do
          [
            "2015-02-01 L LP\n",
            "2015-02-02 L LP\n",
            "2015-02-03 L LP\n",
            "2015-02-04 S MR\n",
            "2015-02-05 S MR\n",
            "2015-02-06 S MR\n"
          ]
        end
        let(:expected_output) do
          "2015-02-01 L LP 6.90 -\n2015-02-02 L LP 6.90 -\n2015-02-03 L LP 0.00 6.90\n" \
            "2015-02-04 S MR 1.50 0.50\n2015-02-05 S MR 1.50 0.50\n2015-02-06 S MR 1.50 0.50\n"
        end

        it 'caps total discounts at 10 EUR' do
          expect { processor.run }.to output(expected_output).to_stdout
        end
      end

      context 'when discount would exceed 10 EUR limit' do
        let(:input_lines) do
          [
            "2015-02-01 S MR\n",
            "2015-02-02 S MR\n",
            "2015-02-03 S MR\n",
            "2015-02-04 S MR\n",
            "2015-02-05 S MR\n",
            "2015-02-06 S MR\n",
            "2015-02-07 S MR\n",
            "2015-02-08 L LP\n",
            "2015-02-09 L LP\n",
            "2015-02-10 L LP\n"
          ]
        end
        let(:expected_output) do
          [
            "2015-02-01 S MR 1.50 0.50",
            "2015-02-02 S MR 1.50 0.50",
            "2015-02-03 S MR 1.50 0.50",
            "2015-02-04 S MR 1.50 0.50",
            "2015-02-05 S MR 1.50 0.50",
            "2015-02-06 S MR 1.50 0.50",
            "2015-02-07 S MR 1.50 0.50",
            "2015-02-08 L LP 6.90 -",
            "2015-02-09 L LP 6.90 -",
            "2015-02-10 L LP 0.40 6.50"
          ].join("\n") + "\n"
        end

        it 'reduces discount to stay within 10 EUR limit' do
          expect { processor.run }.to output(expected_output).to_stdout
        end
      end

      context 'when discount limit is reached mid-discount' do
        let(:input_lines) do
          [
            "2015-02-01 S MR\n",
            "2015-02-02 S MR\n",
            "2015-02-03 S MR\n",
            "2015-02-04 S MR\n",
            "2015-02-05 S MR\n",
            "2015-02-06 S MR\n",
            "2015-02-07 S MR\n",
            "2015-02-08 S MR\n",
            "2015-02-09 L LP\n",
            "2015-02-10 L LP\n",
            "2015-02-11 L LP\n"
          ]
        end
        let(:expected_output) do
          [
            "2015-02-01 S MR 1.50 0.50",
            "2015-02-02 S MR 1.50 0.50",
            "2015-02-03 S MR 1.50 0.50",
            "2015-02-04 S MR 1.50 0.50",
            "2015-02-05 S MR 1.50 0.50",
            "2015-02-06 S MR 1.50 0.50",
            "2015-02-07 S MR 1.50 0.50",
            "2015-02-08 S MR 1.50 0.50",
            "2015-02-09 L LP 6.90 -",
            "2015-02-10 L LP 6.90 -",
            "2015-02-11 L LP 0.90 6.00"
          ].join("\n") + "\n"
        end

        it 'applies partial discount when limit is reached' do
          expect { processor.run }.to output(expected_output).to_stdout
        end
      end

      context 'when limit resets for new month' do
        let(:input_lines) do
          [
            "2015-02-01 S MR\n",
            "2015-02-02 S MR\n",
            "2015-02-03 S MR\n",
            "2015-02-04 S MR\n",
            "2015-02-05 S MR\n",
            "2015-02-06 S MR\n",
            "2015-02-07 S MR\n",
            "2015-02-08 S MR\n",
            "2015-02-09 L LP\n",
            "2015-02-10 L LP\n",
            "2015-02-11 L LP\n",
            "2015-03-01 L LP\n",
            "2015-03-02 L LP\n",
            "2015-03-03 L LP\n"
          ]
        end
        let(:expected_output) do
          [
            "2015-02-01 S MR 1.50 0.50",
            "2015-02-02 S MR 1.50 0.50",
            "2015-02-03 S MR 1.50 0.50",
            "2015-02-04 S MR 1.50 0.50",
            "2015-02-05 S MR 1.50 0.50",
            "2015-02-06 S MR 1.50 0.50",
            "2015-02-07 S MR 1.50 0.50",
            "2015-02-08 S MR 1.50 0.50",
            "2015-02-09 L LP 6.90 -",
            "2015-02-10 L LP 6.90 -",
            "2015-02-11 L LP 0.90 6.00",
            "2015-03-01 L LP 6.90 -",
            "2015-03-02 L LP 6.90 -",
            "2015-03-03 L LP 0.00 6.90"
          ].join("\n") + "\n"
        end

        it 'allows full discount in new month after previous month limit was reached' do
          expect { processor.run }.to output(expected_output).to_stdout
        end
      end
    end

    context 'invalid orders' do
      context 'when order has invalid date' do
        let(:input_lines) { ["2015-02-29 S MR\n"] }
        let(:expected_output) { "2015-02-29 S MR Ignored\n" }

        it 'outputs order as ignored' do
          expect { processor.run }.to output(expected_output).to_stdout
        end
      end

      context 'when order has invalid size' do
        let(:input_lines) { ["2015-02-01 XL LP\n"] }
        let(:expected_output) { "2015-02-01 XL LP Ignored\n" }

        it 'outputs order as ignored' do
          expect { processor.run }.to output(expected_output).to_stdout
        end
      end

      context 'when order has invalid operator' do
        let(:input_lines) { ["2015-02-01 S USPS\n"] }
        let(:expected_output) { "2015-02-01 S USPS Ignored\n" }

        it 'outputs order as ignored' do
          expect { processor.run }.to output(expected_output).to_stdout
        end
      end

      context 'when mixing valid and invalid orders' do
        let(:input_lines) do
          [
            "2015-02-01 S MR\n",
            "2015-02-29 S MR\n",
            "2015-02-02 L LP\n"
          ]
        end
        let(:expected_output) { "2015-02-01 S MR 1.50 0.50\n2015-02-29 S MR Ignored\n2015-02-02 L LP 6.90 -\n" }

        it 'processes valid orders and ignores invalid ones' do
          expect { processor.run }.to output(expected_output).to_stdout
        end
      end
    end

    context 'no discount scenarios (default rule)' do
      context 'when M order from LP' do
        let(:input_lines) { ["2015-02-01 M LP\n"] }
        let(:expected_output) { "2015-02-01 M LP 4.90 -\n" }

        it 'applies no discount' do
          expect { processor.run }.to output(expected_output).to_stdout
        end
      end

      context 'when M order from MR' do
        let(:input_lines) { ["2015-02-01 M MR\n"] }
        let(:expected_output) { "2015-02-01 M MR 3.00 -\n" }

        it 'applies no discount' do
          expect { processor.run }.to output(expected_output).to_stdout
        end
      end

      context 'when L order from MR' do
        let(:input_lines) { ["2015-02-01 L MR\n"] }
        let(:expected_output) { "2015-02-01 L MR 4.00 -\n" }

        it 'applies no discount' do
          expect { processor.run }.to output(expected_output).to_stdout
        end
      end
    end
  end
end
