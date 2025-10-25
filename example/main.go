components {
  id: "main"
  component: "/main.script"
  properties {
    id: "image"
    value: "/assets/dog.tilesource"
    type: PROPERTY_TYPE_HASH
  }
}
components {
  id: "gui"
  component: "/main.gui"
}
embedded_components {
  id: "sprite_factory"
  type: "factory"
  data: "prototype: \"/sprite.go\"\n"
  ""
}
