// Code generated by hertz generator.

package main

import (
	"context"
	"github.com/MyGoFor/E-commerce/app/frontend/infra/rpc"
	frontendutils "github.com/MyGoFor/E-commerce/app/frontend/utils"
	"github.com/MyGoFor/E-commerce/common/mtl"
	prometheus "github.com/hertz-contrib/monitor-prometheus"
	"github.com/hertz-contrib/sessions"
	"github.com/hertz-contrib/sessions/redis"
	"os"
	"time"

	"github.com/MyGoFor/E-commerce/app/frontend/biz/router"
	"github.com/MyGoFor/E-commerce/app/frontend/conf"
	"github.com/cloudwego/hertz/pkg/app"
	"github.com/cloudwego/hertz/pkg/app/middlewares/server/recovery"
	"github.com/cloudwego/hertz/pkg/app/server"
	"github.com/cloudwego/hertz/pkg/common/hlog"
	"github.com/cloudwego/hertz/pkg/common/utils"
	"github.com/cloudwego/hertz/pkg/protocol/consts"
	"github.com/hertz-contrib/cors"
	"github.com/hertz-contrib/gzip"
	"github.com/hertz-contrib/logger/accesslog"
	hertzlogrus "github.com/hertz-contrib/logger/logrus"
	hertzobslogrus "github.com/hertz-contrib/obs-opentelemetry/logging/logrus"
	hertztracing "github.com/hertz-contrib/obs-opentelemetry/tracing"
	"github.com/hertz-contrib/pprof"
	"github.com/joho/godotenv"
	"go.uber.org/zap/zapcore"
	"gopkg.in/natefinch/lumberjack.v2"
	_ "net/http/pprof"
)

var (
	ServiceName  = frontendutils.ServiceName
	MetricsPort  = conf.GetConf().Hertz.MatricesPort
	RegistryAddr = conf.GetConf().Hertz.RegistryAddr
)

func main() {
	//go func() {
	//	log.Println(http.ListenAndServe("localhost:6060", nil)) // 开启 pprof 服务
	//}()

	_ = godotenv.Load()
	consul, registryInfo := mtl.InitMetric(ServiceName, MetricsPort, RegistryAddr)
	defer consul.Deregister(registryInfo) // 反注册掉 prometheus 上的实例

	//p := mtl.InitTracing(ServiceName)
	//defer p.Shutdown(context.Background())

	// init dal
	// dal.Init()
	rpc.Init()

	address := conf.GetConf().Hertz.Address

	tracer, cfg := hertztracing.NewServerTracer()
	h := server.New(server.WithHostPorts(address),
		server.WithTracer(prometheus.NewServerTracer("", "", prometheus.WithDisableServer(true), prometheus.WithRegistry(mtl.Registry))),
		tracer,
	)
	h.Use(hertztracing.ServerMiddleware(cfg))

	registerMiddleware(h)

	// add a ping route to test
	h.GET("/ping", func(c context.Context, ctx *app.RequestContext) {
		ctx.JSON(consts.StatusOK, utils.H{"ping": "pong"})
	})

	router.GeneratedRegister(h)
	h.LoadHTMLGlob("template/*")
	h.Static("/static", "./")

	h.GET("/sign-in", func(ctx context.Context, c *app.RequestContext) {
		c.HTML(consts.StatusOK, "sign-in", utils.H{"Title": "Sign In"})
	})
	h.GET("sign-up", func(ctx context.Context, c *app.RequestContext) {
		c.HTML(consts.StatusOK, "sign-up", utils.H{"Title": "Sign Up"})
	})
	h.GET("/about", func(ctx context.Context, c *app.RequestContext) {
		//_, err := rpc.CasbinClient.Ok(ctx, &casbin.OkReq{Sub: "12@qq.com", Obj: "/about", Act: "GET"})
		//if err != nil {
		//	c.JSON(consts.StatusOK, utils.H{"message": err.Error()})
		//	return
		//}
		hlog.CtxInfof(ctx, "E-commerce shop about page")
		c.HTML(consts.StatusOK, "about", utils.H{"Title": "About"})
	})
	h.GET("/ai", func(ctx context.Context, c *app.RequestContext) {
		c.HTML(consts.StatusOK, "ai", utils.H{"Title": "AI"})
	})

	h.Spin()
}

func registerMiddleware(h *server.Hertz) {
	store, _ := redis.NewStore(10, "tcp", conf.GetConf().Redis.Address, "", []byte(os.Getenv("SESSION_SECRET")))
	h.Use(sessions.New("E-commerce", store))

	// log
	logger := hertzobslogrus.NewLogger(hertzobslogrus.WithLogger(hertzlogrus.NewLogger().Logger()))
	hlog.SetLogger(logger)
	hlog.SetLevel(conf.LogLevel())
	var flushInterval time.Duration
	if os.Getenv("GO_ENV") == "online" { // 生产环境每分钟刷新,测试环境每秒钟
		flushInterval = time.Minute
	} else {
		flushInterval = time.Second
	}
	asyncWriter := &zapcore.BufferedWriteSyncer{
		WS: zapcore.AddSync(&lumberjack.Logger{
			Filename:   conf.GetConf().Hertz.LogFileName,
			MaxSize:    conf.GetConf().Hertz.LogMaxSize,
			MaxBackups: conf.GetConf().Hertz.LogMaxBackups,
			MaxAge:     conf.GetConf().Hertz.LogMaxAge,
		}),
		FlushInterval: flushInterval,
	}
	hlog.SetOutput(asyncWriter)
	h.OnShutdown = append(h.OnShutdown, func(ctx context.Context) {
		asyncWriter.Sync()
	})

	// pprof
	if conf.GetConf().Hertz.EnablePprof {
		pprof.Register(h)
	}

	// gzip
	if conf.GetConf().Hertz.EnableGzip {
		h.Use(gzip.Gzip(gzip.DefaultCompression))
	}

	// access log
	if conf.GetConf().Hertz.EnableAccessLog {
		h.Use(accesslog.New())
	}

	// recovery
	h.Use(recovery.Recovery())

	// cores
	h.Use(cors.Default())
}
