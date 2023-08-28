import 'dart:ui';

import 'model/attribute.dart';
import 'model/tag.dart';
import 'model/location.dart';
import 'dart:developer';
class Tools
{
  static String findValue(List<Attribute> attributes, String name)
  {
      String rc = "";
      try {
        Attribute attr = attributes.firstWhere((element) =>
        element.name == name);
        if ((attr != null) && (attr.value != null))
          rc = attr.value!;
      }
      catch (error)
      {
        log(error.toString());
      }
      return rc;
  }
  static Tag? findTag(List<Tag> tags, String id)
  {
    Tag? rc = null;
    try
    {
      rc = tags.firstWhere((element) => element.tagId == id);
    }
    catch(e)
    {

    }
    return rc;
  }
  static Offset getTagOffset(int x, int y, double width_scale, double height_scale)
  {
    Offset rc = Offset(x/width_scale, y/height_scale);
    return rc;
  }
  static Location? findLocation(List<Location> locations, String id)
  {
    Location? rc = null;
    try
    {
      rc = locations.firstWhere((element) => element.id == id);
    }
    catch(e)
    {

    }
    return rc;
  }
}