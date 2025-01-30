# frozen_string_literal: true

shared_examples_for 'statuses' do
  let(:obj_with_status) { described_class.new }

  it 'requires a status' do
    obj_with_status.status = nil
    expect(obj_with_status.valid?).to be false
    expect(obj_with_status.errors[:status].join).to include "can't be blank"
  end

  it 'requires a valid status' do
    obj_with_status.status = 'single'
    expect(obj_with_status.valid?).to be false
    expect(obj_with_status.errors[:status].join).to include 'is not included'
  end

  it 'assigns the correct badge class' do
    obj_with_status.status = Statuses::COMPLETED
    expect(obj_with_status.badge_class).to be Statuses::Style::COMPLETED
  end
end
