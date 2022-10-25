package commonUtils.xml;

import org.xmlpull.v1.XmlPullParser;

/**
 * This class is designed to be used as a template to parse any xml document
 * All its internal function come from XmlPullParser i.e this is a simple wrapper of XmlPullParser
 * with provide some handy utilities
 */
public class XmlParseTemplate {

    /**
     * Parser current tag by to callback all its child tag , client must provide {@subTagHandler} to handle its interest child tag
     * and return true for had handled, if return is false ,{@parse} will skip this child tag to next same level child
     *
     * @param parser
     * @param tag           current parent tag,  and XmlPullParser's event must is START_TAG
     * @param subTagHandler
     * @throws Exception
     */
    static public void parse(XmlPullParser parser, String tag, SubTagHandler subTagHandler) throws Exception {
        parser.require(XmlPullParser.START_TAG, null, tag);
        while (parser.next() != XmlPullParser.END_TAG) {
            if (parser.getEventType() != XmlPullParser.START_TAG) {
                continue;
            }
            if (!subTagHandler.handle(parser, parser.getName())) {
                skipTag(parser);
            }

        }
    }

    static public String readText(XmlPullParser parser) throws Exception {
        String result = "";
        if (parser.next() == XmlPullParser.TEXT) {
            result = parser.getText();
            parser.nextTag();
        }
        return result;
    }

    static public void moveToTag(XmlPullParser parser, String tag) throws Exception {
        while (parser.next() != XmlPullParser.END_TAG) {
            if (parser.getEventType() != XmlPullParser.START_TAG) {
                continue;
            }
            if (parser.getName().equalsIgnoreCase(tag)) {
                return;
            }
        }
        throw new RuntimeException("can not find tag:" + tag + "at all xml docs");
    }

    /**
     * skip current tag and move to the next same level tag
     *
     * @param parser parser's event must is START_TAG
     * @throws Exception
     */
    static public void skipTag(XmlPullParser parser) throws Exception {
        if (parser.getEventType() != XmlPullParser.START_TAG) {
            throw new IllegalStateException();
        }
        int depth = 1;
        while (depth != 0) {
            switch (parser.next()) {
                case XmlPullParser.END_TAG:
                    depth--;
                    break;
                case XmlPullParser.START_TAG:
                    depth++;
                    break;
            }
        }
    }

    public interface SubTagHandler {
        boolean handle(XmlPullParser parser, String subTag) throws Exception;
    }
}
