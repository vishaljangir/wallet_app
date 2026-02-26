class AddMessageToTransfers < ActiveRecord::Migration[8.1]
  def change
    add_column :transfers, :message, :string
  end
end
