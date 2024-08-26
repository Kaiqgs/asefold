components {
  id: "main"
  component: "/main/main.script"
  properties {
    id: "image"
    value: "/assets/dummy.tilesource"
    type: PROPERTY_TYPE_HASH
  }
}
components {
  id: "gui"
  component: "/main/main.gui"
}
embedded_components {
  id: "sprite_factory"
  type: "factory"
  data: "prototype: \"/main/sprite.go\"\n"
  ""
}
