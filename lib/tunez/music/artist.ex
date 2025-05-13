defmodule Tunez.Music.Artist do
  use Ash.Resource, otp_app: :tunez, domain: Tunez.Music, data_layer: AshPostgres.DataLayer

  postgres do
    table "artists"
    repo Tunez.Repo

    custom_indexes do
      index "name gin_trgm_ops", name: "artists_name_gin_index", using: "GIN"
    end
  end

  actions do
    # create :create do
    #   accept [:name, :biography]
    # end

    # read :read do
    #   primary? true
    # end

    # update :update do
    #   accept [:name, :biography]
    # end

    # destroy :destroy do
    # end
    defaults [:create, :read, :destroy]
    default_accept [:name, :biography]

    read :search do
      argument :query, :ci_string do
        constraints allow_empty?: true
        default ""
      end

      filter expr(contains(name, ^arg(:query)))
      pagination offset?: true, default_limit: 12
    end

    update :update do
      require_atomic? false
      accept [:name, :biography]

      # change fn changeset, _context ->
      #          new_name = Ash.Changeset.get_attribute(changeset, :name)
      #          previous_name = Ash.Changeset.get_data(changeset, :name)
      #          previous_names = Ash.Changeset.get_data(changeset, :previous_names)

      #          names =
      #            [previous_name | previous_names]
      #            |> Enum.uniq()
      #            |> Enum.reject(fn name -> name == new_name end)

      #          Ash.Changeset.change_attribute(changeset, :previous_names, names)
      #        end,
      #        where: [changing(:name)]
      change Tunez.Music.Changes.UpdatePreviousNames, where: [changing(:name)]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :biography, :string

    attribute :previous_names, {:array, :string} do
      default []
    end

    create_timestamp :inserted_at, public?: true

    update_timestamp :updated_at, public?: true
  end

  relationships do
    has_many :albums, Tunez.Music.Album do
      sort year_released: :desc
    end
  end

  calculations do
    # calculate :album_count, :integer, expr(count(albums))
    # calculate :latest_album_year_released, :integer, expr(first(albums, field: :year_released))
    # calculate :cover_image_url, :string, expr(first(albums, field: :cover_image_url))
  end

  aggregates do
    # calculate :album_count, :integer, expr(count(albums))
    count :album_count, :albums do
      public? true
    end

    first :latest_album_year_released, :albums, :year_released do
      public? true
    end

    first :cover_image_url, :albums, :cover_image_url
  end
end
