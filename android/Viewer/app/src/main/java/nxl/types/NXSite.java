package nxl.types;

import java.util.List;

// fixbug: 1/20/2016 make NxSite extents from NxFolder , not NxFileBase
public class NXSite extends NXFolder {
    {
        super.setSite(true);
        super.setIsFolder(true);
    }

    public NXSite() {
    }

    public NXSite(String localPath, String cloudPath, String name, long size) {
        super.setLocalPath(localPath);
        super.setCloudPath(cloudPath);
        super.setName(name);
        super.setSize(size);
        super.setSite(true);
        super.setIsFolder(true);
    }

    // recursive to find the node
    //
    @Override
    public INxFile findNode(String path) {
        INxFile rt;
        // recursive way out
        if (getLocalPath().equalsIgnoreCase(path))
            return this;
        else {
            List<INxFile> children = this.getChildren();
            for (INxFile obj : children) {
                //remove '/' sign
                if (path.endsWith("/"))
                    path = path.substring(0, path.length() - 1);
                // Match test
                if (path.regionMatches(true, 0, obj.getLocalPath(), 0, obj.getLocalPath().length())) {
                    rt = obj.findNode(path);
                    if (rt != null)
                        return rt;
                }
                continue;
            }
            return null;

        }


    }
}