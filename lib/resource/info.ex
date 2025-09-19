defmodule AshTranslation.Resource.Info do
  use Spark.InfoGenerator, extension: AshTranslation.Resource, sections: [:translations]
end
