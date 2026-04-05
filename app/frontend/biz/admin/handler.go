package admin

import (
	"context"
	"strconv"

	"github.com/cloudwego/hertz/pkg/app"
	"github.com/cloudwego/hertz/pkg/app/server"
	"github.com/cloudwego/hertz/pkg/common/utils"
	"github.com/cloudwego/hertz/pkg/protocol/consts"
	"github.com/hertz-contrib/sessions"
)

const (
	adminUsername = "admin"
	adminPassword = "admin"
)

type productForm struct {
	Name        string  `form:"name"`
	Description string  `form:"description"`
	Picture     string  `form:"picture"`
	Price       float32 `form:"price"`
	Categories  string  `form:"categories"`
}

func RegisterRoutes(h *server.Hertz) {
	auth := adminSessionAuth()
	h.GET("/admin/login", adminLoginPage)
	h.POST("/admin/login", adminLoginSubmit)
	h.POST("/admin/logout", auth, adminLogout)
	h.GET("/admin/logout", auth, adminLogout)
	h.GET("/admin", auth, redirectAdminProducts)
	h.GET("/admin/products", auth, listProducts)
	h.GET("/admin/products/new", auth, newProductPage)
	h.POST("/admin/products/new", auth, createProduct)
	h.GET("/admin/products/edit", auth, editProductPage)
	h.POST("/admin/products/edit", auth, updateProduct)
	h.POST("/admin/products/delete", auth, deleteProduct)
}

func adminSessionAuth() app.HandlerFunc {
	return func(ctx context.Context, c *app.RequestContext) {
		session := sessions.Default(c)
		adminAuthed := session.Get("admin_authed")
		if adminAuthed == nil || adminAuthed != true {
			c.Redirect(consts.StatusFound, []byte("/admin/login"))
			c.Abort()
			return
		}
		c.Next(ctx)
	}
}

func adminLoginPage(ctx context.Context, c *app.RequestContext) {
	c.HTML(consts.StatusOK, "admin_login", utils.H{
		"Title": "后台 - 登录",
		"Error": string(c.Query("error")),
	})
}

func adminLoginSubmit(ctx context.Context, c *app.RequestContext) {
	username := string(c.FormValue("username"))
	password := string(c.FormValue("password"))
	if username != adminUsername || password != adminPassword {
		c.Redirect(consts.StatusFound, []byte("/admin/login?error=1"))
		return
	}

	session := sessions.Default(c)
	session.Set("admin_authed", true)
	if err := session.Save(); err != nil {
		c.String(consts.StatusInternalServerError, err.Error())
		return
	}
	c.Redirect(consts.StatusFound, []byte("/admin/products"))
}

func adminLogout(ctx context.Context, c *app.RequestContext) {
	session := sessions.Default(c)
	session.Delete("admin_authed")
	if err := session.Save(); err != nil {
		c.String(consts.StatusInternalServerError, err.Error())
		return
	}
	c.Redirect(consts.StatusFound, []byte("/admin/login"))
}

func redirectAdminProducts(ctx context.Context, c *app.RequestContext) {
	c.Redirect(consts.StatusFound, []byte("/admin/products"))
}

func listProducts(ctx context.Context, c *app.RequestContext) {
	db, err := getDB()
	if err != nil {
		c.String(consts.StatusInternalServerError, err.Error())
		return
	}
	q := string(c.Query("q"))
	var items []Product
	query := db.WithContext(ctx).Model(&Product{})
	if q != "" {
		like := "%" + q + "%"
		query = query.Where("name LIKE ? OR description LIKE ?", like, like)
	}
	if err = query.Order("id DESC").Find(&items).Error; err != nil {
		c.String(consts.StatusInternalServerError, err.Error())
		return
	}
	c.HTML(consts.StatusOK, "admin_products", utils.H{
		"Title": "后台 - 商品管理",
		"Items": items,
		"Query": q,
	})
}

func newProductPage(ctx context.Context, c *app.RequestContext) {
	c.HTML(consts.StatusOK, "admin_product_form", utils.H{
		"Title":       "后台 - 新增商品",
		"FormAction":  "/admin/products/new",
		"SubmitLabel": "创建商品",
		"Product":     Product{},
		"Categories":  "",
	})
}

func createProduct(ctx context.Context, c *app.RequestContext) {
	db, err := getDB()
	if err != nil {
		c.String(consts.StatusInternalServerError, err.Error())
		return
	}
	var req productForm
	if err = c.BindAndValidate(&req); err != nil {
		c.String(consts.StatusBadRequest, err.Error())
		return
	}
	item := Product{
		Name:        req.Name,
		Description: req.Description,
		Picture:     req.Picture,
		Price:       req.Price,
		Categories:  parseCategories(req.Categories),
	}
	if err = db.WithContext(ctx).Create(&item).Error; err != nil {
		c.String(consts.StatusInternalServerError, err.Error())
		return
	}
	c.Redirect(consts.StatusFound, []byte("/admin/products"))
}

func editProductPage(ctx context.Context, c *app.RequestContext) {
	db, err := getDB()
	if err != nil {
		c.String(consts.StatusInternalServerError, err.Error())
		return
	}
	id, err := strconv.ParseUint(string(c.Query("id")), 10, 32)
	if err != nil {
		c.String(consts.StatusBadRequest, "invalid id")
		return
	}
	var item Product
	if err = db.WithContext(ctx).First(&item, uint32(id)).Error; err != nil {
		c.String(consts.StatusNotFound, "product not found")
		return
	}
	c.HTML(consts.StatusOK, "admin_product_form", utils.H{
		"Title":       "后台 - 编辑商品",
		"FormAction":  "/admin/products/edit?id=" + strconv.FormatUint(id, 10),
		"SubmitLabel": "保存修改",
		"Product":     item,
		"Categories":  categoriesToInput(item.Categories),
	})
}

func updateProduct(ctx context.Context, c *app.RequestContext) {
	db, err := getDB()
	if err != nil {
		c.String(consts.StatusInternalServerError, err.Error())
		return
	}
	id, err := strconv.ParseUint(string(c.Query("id")), 10, 32)
	if err != nil {
		c.String(consts.StatusBadRequest, "invalid id")
		return
	}
	var req productForm
	if err = c.BindAndValidate(&req); err != nil {
		c.String(consts.StatusBadRequest, err.Error())
		return
	}
	updates := map[string]interface{}{
		"name":        req.Name,
		"description": req.Description,
		"picture":     req.Picture,
		"price":       req.Price,
		"categories":  parseCategories(req.Categories),
	}
	if err = db.WithContext(ctx).Model(&Product{}).Where("id = ?", uint32(id)).Updates(updates).Error; err != nil {
		c.String(consts.StatusInternalServerError, err.Error())
		return
	}
	c.Redirect(consts.StatusFound, []byte("/admin/products"))
}

func deleteProduct(ctx context.Context, c *app.RequestContext) {
	db, err := getDB()
	if err != nil {
		c.String(consts.StatusInternalServerError, err.Error())
		return
	}
	id, err := strconv.ParseUint(string(c.FormValue("id")), 10, 32)
	if err != nil {
		c.String(consts.StatusBadRequest, "invalid id")
		return
	}
	if err = db.WithContext(ctx).Delete(&Product{}, uint32(id)).Error; err != nil {
		c.String(consts.StatusInternalServerError, err.Error())
		return
	}
	c.Redirect(consts.StatusFound, []byte("/admin/products"))
}

