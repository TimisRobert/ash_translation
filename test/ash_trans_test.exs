defmodule AshTranslation.Test do
  use ExUnit.Case

  test "default locale" do
    post =
      Ash.Changeset.for_create(AshTranslation.Test.Post, :create, %{
        title: "Title",
        body: "Body",
        translations: %{
          it: %{
            title: "Titolo",
            body: "Corpo"
          }
        }
      })
      |> Ash.create!()

    assert %{title: "Title", body: "Body"} =
             AshTranslation.Test.Cldr.AshTranslation.translate(post)
  end

  test "handle missing translations by falling back to default locale" do
    {:ok, _} = Cldr.put_locale(:it)

    post =
      Ash.Changeset.for_create(AshTranslation.Test.Post, :create, %{
        title: "Title",
        body: "Body"
      })
      |> Ash.create!()

    assert %{title: "Title", body: "Body"} =
             AshTranslation.Test.Cldr.AshTranslation.translate(post)
  end

  test "handle missing locale translations by falling back to default locale" do
    {:ok, _} = Cldr.put_locale(:de)

    post =
      Ash.Changeset.for_create(AshTranslation.Test.Post, :create, %{
        title: "Title",
        body: "Body",
        translations: %{
          it: %{
            title: "Titolo",
            body: "Corpo"
          }
        }
      })
      |> Ash.create!()

    assert %{title: "Title", body: "Body"} =
             AshTranslation.Test.Cldr.AshTranslation.translate(post)
  end

  test "handle missing field translations by falling back to default locale" do
    {:ok, _} = Cldr.put_locale(:it)

    post =
      Ash.Changeset.for_create(AshTranslation.Test.Post, :create, %{
        title: "Title",
        body: "Body",
        translations: %{
          it: %{
            body: "Corpo"
          }
        }
      })
      |> Ash.create!()

    assert %{title: "Title", body: "Corpo"} =
             AshTranslation.Test.Cldr.AshTranslation.translate(post)
  end

  test "nested relationships get translated" do
    {:ok, _} = Cldr.put_locale(:it)

    author =
      Ash.Changeset.for_create(AshTranslation.Test.Author, :create, %{
        name: "Name",
        translations: %{
          it: %{
            name: "Nome"
          }
        }
      })
      |> Ash.create!()

    Ash.Changeset.for_create(AshTranslation.Test.Post, :create, %{
      title: "Title",
      body: "Body",
      translations: %{
        it: %{
          body: "Corpo"
        }
      }
    })
    |> Ash.Changeset.manage_relationship(:author, author, type: :append)
    |> Ash.create!()

    author = Ash.load!(author, [:posts])

    assert %{name: "Nome", posts: [%{title: "Title", body: "Corpo"}]} =
             AshTranslation.Test.Cldr.AshTranslation.translate(author)
  end

  test "forms work" do
    AshPhoenix.Form.for_create(AshTranslation.Test.Post, :create,
      as: "post",
      forms: [auto?: true]
    )
    |> AshTranslation.add_forms(AshTranslation.Test.Cldr.AshTranslation.locale_names())
  end

  test "nested list forms work" do
    AshPhoenix.Form.for_update(
      %AshTranslation.Test.Post{
        title: "title",
        tags: [
          %{
            name: "tag 1",
            translations: %{}
          },
          %{
            name: "tag 2",
            translations: %{}
          }
        ]
      },
      :update,
      as: "post",
      forms: [auto?: true]
    )
    |> AshTranslation.add_forms(AshTranslation.Test.Cldr.AshTranslation.locale_names())
    |> AshTranslation.add_forms(AshTranslation.Test.Cldr.AshTranslation.locale_names(), [:tags, 0])
    |> AshTranslation.add_forms(AshTranslation.Test.Cldr.AshTranslation.locale_names(), [:tags, 1])
  end
end
