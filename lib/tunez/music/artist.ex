defmodule Tunez.Music.Artist do
  use Ash.Resource,
    otp_app: :tunez,
    domain: Tunez.Music,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshGraphql.Resource, AshJsonApi.Resource],
    authorizers: [Ash.Policy.Authorizer]

  graphql do
    type :artist

    filterable_fields [
      :album_count,
      :cover_image_url,
      :inserted_at,
      :latest_album_year_released,
      :updated_at
    ]
  end

  json_api do
    type "artist"
    # includes [:albums]
    includes albums: [:tracks]
    derive_filter? false
  end

  postgres do
    table "artists"
    repo Tunez.Repo

    custom_indexes do
      index "name gin_trgm_ops", name: "artists_name_gin_index", using: "GIN"
    end
  end

  resource do
    description "A person or group of people that makes and releases music."
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
      description "List Artists, optionally filtering by name."

      argument :query, :ci_string do
        description "Return only artists with names including the given value."
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

  policies do
    policy action(:create) do
      # authorize_if always()
      authorize_if actor_attribute_equals(:role, :admin)
    end

    policy action(:update) do
      authorize_if actor_attribute_equals(:role, :admin)
      authorize_if actor_attribute_equals(:role, :editor)
    end

    policy action(:destroy) do
      authorize_if actor_attribute_equals(:role, :admin)
    end

    policy action_type(:read) do
      authorize_if always()
    end
  end

  changes do
    change relate_actor(:created_by, allow_nil?: true), on: [:create]
    change relate_actor(:updated_by, allow_nil?: true)
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :biography, :string do
      # allow_nil? true
      public? true
    end

    attribute :previous_names, {:array, :string} do
      default []
      # allow_nil? true
      public? true
    end

    create_timestamp :inserted_at, public?: true

    update_timestamp :updated_at, public?: true
  end

  relationships do
    has_many :albums, Tunez.Music.Album do
      sort year_released: :desc
      public? true
    end

    has_many :follower_relationships, Tunez.Music.ArtistFollower

    many_to_many :followers, Tunez.Accounts.User do
      # through Tunez.Music.ArtistFollower
      join_relationship :follower_relationships
      destination_attribute_on_join_resource :follower_id
    end

    belongs_to :created_by, Tunez.Accounts.User
    belongs_to :updated_by, Tunez.Accounts.User
  end

  calculations do
    # calculate :album_count, :integer, expr(count(albums))
    # calculate :latest_album_year_released, :integer, expr(first(albums, field: :year_released))
    # calculate :cover_image_url, :string, expr(first(albums, field: :cover_image_url))
    calculate :followed_by_me,
              :boolean,
              expr(exists(follower_relationships, follower_id == ^actor(:id))) do
      public? true
    end
  end

  aggregates do
    # calculate :album_count, :integer, expr(count(albums))
    count :album_count, :albums do
      public? true
    end

    count :follower_count, :follower_relationships do
      public? true
    end

    first :latest_album_year_released, :albums, :year_released do
      public? true
    end

    first :cover_image_url, :albums, :cover_image_url
  end
end
