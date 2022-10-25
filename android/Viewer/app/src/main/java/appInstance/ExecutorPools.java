package appInstance;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * this class is designed as to hold all kinds of common thread pools that can be used by other class
 */
final public class ExecutorPools {
    /**
     * all repos may share this service
     * <ul>
     * <li>to prefetch the repo tree at first repo installed</li>
     * <li>single repo may use it to serialize data to disk</li>
     * <li>heartbeat task use it</li>
     * </ul>
     */
    static public ExecutorService COMMON_POOL = Executors.newFixedThreadPool(Runtime.getRuntime().availableProcessors() * 2 + 1, new ThreadFactory() {
        private final AtomicInteger mCount = new AtomicInteger(1);

        @Override
        public Thread newThread(Runnable r) {
            return new Thread(r, "NEXTLABS_COMMON_POOL #" + mCount.getAndIncrement());
        }
    });

    /**
     * single repo use will use it to refresh current working folder
     * <p/>
     * NOTICE!
     * in order to ensure the effective response of UI operation, other code should not use this
     * service except repo's refreshing
     */
    static public ExecutorService REPO_FORCE_REFRESHER = Executors.newSingleThreadExecutor(new ThreadFactory() {
        private final AtomicInteger mCount = new AtomicInteger(1);

        @Override
        public Thread newThread(Runnable r) {
            return new Thread(r, "NEXTLABS_REPO_REFRESHER #" + mCount.getAndIncrement());
        }
    });

}
