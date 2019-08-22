defmodule LimitOrder.Repo.Migrations.CreateTrigger do
  use Ecto.Migration

  def change do
    # execute """
    #   CREATE OR REPLACE FUNCTION notify_coinbase_updates_changes()
    #   RETURNS trigger AS $$
    #   DECLARE
    #     current_row RECORD;
    #   BEGIN
    #     IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
    #       current_row := NEW;
    #     ELSE
    #       current_row := OLD;
    #     END IF;
    #     PERFORM pg_notify(
    #       'coinbase_updates_changes',
    #       json_build_object(
    #         'table', TG_TABLE_NAME,
    #         'type', TG_OP,
    #         'id', current_row.id,
    #         'data', row_to_json(current_row)
    #       )::text
    #     );
    #     RETURN current_row;
    #   END;
    #   $$ LANGUAGE plpgsql;
    # """

    # execute """
    #   CREATE TRIGGER notify_coinbase_updates_changes_trigger
    #   AFTER INSERT OR UPDATE OR DELETE
    #   ON coinbase_updates
    #   FOR EACH ROW
    #   EXECUTE PROCEDURE notify_coinbase_updates_changes();
    # """
  end
end
