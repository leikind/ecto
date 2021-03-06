defrecord Ecto.Reflections.HasOne, [:field, :owner, :associated, :key, :assoc_key] do
  @moduledoc """
  The reflection record for a `has_one` association. Its fields are:

  * `field` - The name of the association field on the model;
  * `owner` - The model where the association was defined;
  * `associated` - The model that is associated;
  * `key` - The key on the `owner` model used for the association;
  * `assoc_key` - The key on the `associated` model used for the association;
  """
end

defmodule Ecto.Associations.HasOne do
  @moduledoc """
  A has_one association.

  ## Reflection

  Any association module will generate the `__assoc__` function that can be
  used for runtime introspection of the association.

  * `__assoc__(:loaded, assoc)` - Returns the loaded entities or `:not_loaded`;
  * `__assoc__(:loaded, value, assoc)` - Sets the loaded entities;
  * `__assoc__(:target, assoc)` - Returns the model where the association was
                                  defined;
  * `__assoc__(:name, assoc)` - Returns the name of the association field on the
                                model;
  * `__assoc__(:primary_key, assoc)` - Returns the primary key (used when
                                       creating a an model with `new/2`);
  * `__assoc__(:primary_key, value, assoc)` - Sets the primary key;
  * `__assoc__(:new, name, target)` - Creates a new association with the given
                                      name and target;
  """

  alias Ecto.Reflections.HasOne, as: Refl

  @not_loaded :not_loaded

  # Needs to be defrecordp because we don't want pollute the module
  # with functions generated for the record
  defrecordp :assoc, __MODULE__, [:loaded, :target, :name, :primary_key]

  @doc """
  Creates a new struct of the associated model with the foreign key field set
  to the primary key of the parent model.
  """
  def new(params \\ [], assoc(target: target, name: name, primary_key: pk_value)) do
    refl = Refl[] = target.__schema__(:association, name)
    fk = refl.assoc_key
    struct(refl.associated, [{fk, pk_value}] ++ params)
  end

  @doc """
  Returns the associated struct. Raises `AssociationNotLoadedError` if the
  association is not loaded.
  """
  def get(assoc(loaded: @not_loaded, target: target, name: name)) do
    refl = target.__schema__(:association, name)
    raise Ecto.AssociationNotLoadedError,
      type: :has_one, owner: refl.owner, name: name
  end

  def get(assoc(loaded: loaded)) do
    loaded
  end

  @doc """
  Returns `true` if the association is loaded.
  """
  def loaded?(assoc(loaded: @not_loaded)), do: false
  def loaded?(_), do: true

  @doc false
  Enum.each [:loaded, :target, :name, :primary_key], fn field ->
    def __assoc__(unquote(field), record) do
      assoc([{unquote(field), var}]) = record
      var
    end
  end

  @doc false
  Enum.each [:loaded, :primary_key], fn field ->
    def __assoc__(unquote(field), value, record) do
      assoc(record, [{unquote(field), value}])
    end
  end

  def __assoc__(:new, name, target) do
    assoc(name: name, target: target, loaded: @not_loaded)
  end
end

defimpl Inspect, for: Ecto.Associations.HasOne do
  import Inspect.Algebra

  def inspect(assoc, opts) do
    name        = assoc.__assoc__(:name)
    target      = assoc.__assoc__(:target)
    refl        = target.__schema__(:association, name)
    associated  = refl.associated
    references  = refl.key
    foreign_key = refl.assoc_key
    kw = [
      name: name,
      target: target,
      associated: associated,
      references: references,
      foreign_key: foreign_key
    ]
    concat ["#Ecto.Associations.HasOne<", Inspect.List.inspect(kw, opts), ">"]
  end
end
