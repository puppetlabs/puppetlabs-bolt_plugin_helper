require_relative '../lib/plugin_helper.rb'

describe RubyPluginHelper do
  include RubyPluginHelper

  context '#required_data' do
    let(:template) do
      { name: 'public_dns_name',
        uri: 'public_dns_name',
        non_bolt_key: 'value.with.dots' }
    end
    let(:output) do
      [['public_dns_name'],
       ['value', 'with', 'dots']]
    end

    it 'returns array of values to lookup' do
      expect(required_data(template)).to eq(output)
    end

    it 'returns empty array if template is empty' do
      expect(required_data({})).to eq([])
    end
  end

  context '#apply_mapping' do
    let(:template) do
      { name: 'look.up',
        config: {
          ssh: {
            user: 'user.strange',
            'run-as-command': 'im.an.array'
          }
        } }
    end
    let(:lookups) do
      [{
        'look' => { 'up' => 'name' },
        'user' => { 'strange' => 'user' },
        'im' => { 'an' => { 'array' => ['sudo', 'let', 'me', 'in'] } }
      },
       {
         'look' => { 'up' => 'down' },
         'user' => { 'strange' => 'charm' },
         'im' => { 'an' => { 'array' => ['sudo', 'top', 'bottom'] } }
       }]
    end
    let(:output) do
      [{ name: 'name',
         config: {
           ssh: {
             user: 'user',
             'run-as-command': ['sudo', 'let', 'me', 'in']
           }
         } },
       { name: 'down',
         config: {
           ssh: {
             user: 'charm',
             'run-as-command': ['sudo', 'top', 'bottom']
           }
         } }]
    end

    it 'populates template with lookups, including nested hashes' do
      expect(lookups.map { |l| apply_mapping(template, l) }).to eq(output)
    end

    it 'raises an error if a lookup is not a string, array, or hash' do
      expect { apply_mapping({ 'int': 2 }, [{ 2 => '2' }]) }
        .to raise_error(StandardError, %r{string, array, or hash. Got Integer})
    end
  end
end
